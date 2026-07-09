"""Outbound approval plugin.

Hard gate for communications that leave Hermes: messaging platforms, Gmail/email
send/reply paths, social posts/DMs, and common terminal invocations that send
mail/messages.  The model may draft freely; delivery waits for the user's
explicit /approve response in the gateway approval flow.
"""

from __future__ import annotations

import json
import logging
import re
from typing import Any, Mapping


logger = logging.getLogger(__name__)

_DESCRIPTION = "outbound communication requires explicit user approval"
_PATTERN_KEY = "outbound_communication"
_APPROVAL_CHOICES = {"once", "session", "always"}

_DIRECT_SEND_TOOLS = {
    "send_message",
}

_COMM_DOMAINS = (
    "email",
    "gmail",
    "mail",
    "smtp",
    "slack",
    "matrix",
    "telegram",
    "discord",
    "signal",
    "sms",
    "whatsapp",
    "weixin",
    "feishu",
    "yuanbao",
    "twitter",
    "xurl",
    "tweet",
    "social",
    "ntfy",
    "webhook",
)

_OUTBOUND_ACTIONS = (
    "send",
    "reply",
    "post",
    "publish",
    "message",
    "dm",
    "share",
    "notify",
    "deliver",
    "comment",
)

_READ_ONLY_ACTIONS = {
    "list",
    "search",
    "get",
    "read",
    "fetch",
    "inspect",
    "labels",
    "status",
    "check",
}

_TERMINAL_PATTERNS: tuple[re.Pattern[str], ...] = tuple(
    re.compile(pat, re.IGNORECASE | re.DOTALL)
    for pat in (
        # Hermes Google Workspace wrappers.  The loose variant catches Python
        # scripts that construct argv lists like ["account.py", ..., "gmail",
        # "reply"] as well as direct shell invocations.
        r"\b(?:account|google_api)\.py\b[\s\S]{0,700}\bgmail\b[\s\S]{0,160}\b(?:send|reply)\b",
        r"\bgws\b[\s\S]{0,160}\bgmail\b[\s\S]{0,80}\b(?:send|reply)\b",
        # Common mail CLIs.
        r"\bhimalaya\b[\s\S]{0,200}\b(?:template\s+send|message\s+(?:send|reply|write)|send)\b",
        r"\bmail\b[\s\S]{0,160}(?:^|\s)(?:-s|--subject|to:)\b",
        r"\b(?:sendmail|msmtp|mutt|mailx|aerc)\b[\s\S]{0,200}(?:^|\s)(?:-s|--subject|to:|send|compose|reply)\b",
        # Social / chat CLIs.
        r"\bxurl\b[\s\S]{0,160}\b(?:post|tweet|dm|reply|send)\b",
        r"\bgh\b[\s\S]{0,160}\b(?:issue|pr)\b[\s\S]{0,120}\bcomment\b",
        r"\bntfy\b[\s\S]{0,120}\b(?:publish|send|notify)\b",
        # Direct HTTP/API sends to comms services.
        r"\b(?:curl|http|wget|python\d*(?:\.\d+)?|node|npx)\b[\s\S]{0,1200}\b(?:chat\.postMessage|sendMessage|messages\.send|hooks\.slack\.com/services|slack\.com/api|api\.telegram\.org|discord(?:app)?\.com/api(?:/webhooks)?|matrix\.org|sendgrid|mailgun|twilio|smtp)\b",
    )
)


def register(ctx) -> None:
    ctx.register_hook("pre_tool_call", _pre_tool_call)
    logger.info("outbound-approval plugin loaded")


def _pre_tool_call(tool_name: str, args: Mapping[str, Any] | None = None, **_: Any):
    if not _enabled():
        return None

    args = args if isinstance(args, Mapping) else {}
    reason = _classify(tool_name or "", args)
    if reason is None:
        return None

    approved, block_message = _require_gateway_approval(tool_name or "", args, reason)
    if approved:
        return None

    return {"action": "block", "message": block_message}


def _enabled() -> bool:
    try:
        from hermes_cli.config import cfg_get, load_config  # type: ignore[import-not-found]

        return bool(
            cfg_get(load_config(), "outbound_approval", "enabled", default=True)
        )
    except Exception:
        # Fail closed: if config is unreadable, outbound comms do not leave.
        return True


def _normalize_action(text: str) -> set[str]:
    camel_split = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", str(text or ""))
    return set(re.sub(r"[^A-Za-z0-9]+", " ", camel_split).lower().split())


def _is_read_only_action(text: str) -> bool:
    tokens = _normalize_action(text)
    return bool(tokens) and bool(tokens & _READ_ONLY_ACTIONS)


def _is_outbound_action(text: str) -> bool:
    tokens = _normalize_action(text)
    return bool(tokens & set(_OUTBOUND_ACTIONS))


def _classify(tool_name: str, args: Mapping[str, Any]) -> str | None:
    name = tool_name.lower().strip()

    if name == "tool_call":
        nested_name = str(args.get("name") or args.get("tool_name") or "")
        nested_args = args.get("arguments")
        if not isinstance(nested_args, Mapping):
            nested_args = {}
        nested = _classify(nested_name, nested_args)
        if nested:
            return f"deferred tool {nested_name}: {nested}"
        return None

    if name in _DIRECT_SEND_TOOLS:
        action = str(args.get("action") or "send")
        if _is_read_only_action(action):
            return None
        return "send_message delivery"

    if name == "terminal":
        command = str(args.get("command") or "")
        for pat in _TERMINAL_PATTERNS:
            if pat.search(command):
                return "terminal command appears to send/reply/post a message"
        return None

    domain_hit = any(domain in name for domain in _COMM_DOMAINS)
    action_hit = any(action in name for action in _OUTBOUND_ACTIONS)
    if domain_hit and action_hit:
        return "communication tool name indicates outbound delivery"

    action = str(
        args.get("action")
        or args.get("op")
        or args.get("operation")
        or args.get("method")
        or ""
    ).strip()
    if _is_read_only_action(action):
        return None
    if domain_hit and _is_outbound_action(action):
        return "communication tool action indicates outbound delivery"

    return None


def _require_gateway_approval(
    tool_name: str, args: Mapping[str, Any], reason: str
) -> tuple[bool, str]:
    summary = _approval_summary(tool_name, args, reason)

    try:
        from tools import approval as approval_mod  # type: ignore[import-not-found]

        session_key = approval_mod.get_current_session_key()
        with approval_mod._lock:  # type: ignore[attr-defined]
            notify_cb = approval_mod._gateway_notify_cbs.get(session_key)  # type: ignore[attr-defined]

        if callable(notify_cb):
            decision = approval_mod._await_gateway_decision(  # type: ignore[attr-defined]
                session_key,
                notify_cb,
                {
                    "command": summary,
                    "description": _DESCRIPTION,
                    "pattern_key": _PATTERN_KEY,
                    "pattern_keys": [_PATTERN_KEY],
                },
                surface="gateway",
            )
            choice = decision.get("choice")
            if decision.get("resolved") and choice in _APPROVAL_CHOICES:
                # Approval is per outbound action.  Do not persist session/always
                # bypasses for this policy even if the generic approval UI offers
                # those choices.
                return True, ""
            if not decision.get("resolved"):
                return (
                    False,
                    "BLOCKED: outbound communication approval timed out. Silence is not consent.",
                )
            return False, "BLOCKED: outbound communication denied by user."
    except Exception as exc:
        logger.warning("outbound approval check failed: %s", exc, exc_info=True)
        return (
            False,
            f"BLOCKED: outbound communication approval guard failed closed ({exc}).",
        )

    return (
        False,
        "BLOCKED: outbound communication requires explicit user approval before execution. "
        "Do not retry via another tool or command unless the user approves. "
        "No gateway approval channel is registered for this session. Intended action:\n\n"
        f"{summary}",
    )


def _approval_summary(tool_name: str, args: Mapping[str, Any], reason: str) -> str:
    safe_args = _redact(_jsonish(args))
    if tool_name == "send_message":
        target = args.get("target", "")
        message = str(args.get("message") or "")
        return _truncate(
            f"Tool: send_message\nReason: {reason}\nTarget: {target}\nMessage:\n{_redact(message)}",
            4000,
        )
    if tool_name == "terminal":
        return _truncate(
            f"Tool: terminal\nReason: {reason}\nCommand:\n{_redact(str(args.get('command') or ''))}",
            4000,
        )
    return _truncate(f"Tool: {tool_name}\nReason: {reason}\nArgs:\n{safe_args}", 4000)


def _jsonish(value: Any) -> str:
    try:
        return json.dumps(value, ensure_ascii=False, indent=2, default=str)
    except Exception:
        return repr(value)


def _redact(text: str) -> str:
    try:
        from agent.redact import redact_sensitive_text  # type: ignore[import-not-found]

        return redact_sensitive_text(text, force=True)
    except Exception:
        return "[redacted: redaction unavailable]"


def _truncate(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    return text[: limit - 80] + "\n… [truncated by outbound approval guard]"
