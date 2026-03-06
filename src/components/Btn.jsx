import { P, sans } from '../data/constants.js';

export default function Btn({ children, primary, small, disabled, style, ...props }) {
  return (
    <button
      {...props}
      disabled={disabled}
      aria-disabled={disabled || undefined}
      style={{
        background: primary ? P.grad : "rgba(255,255,255,0.06)",
        color: primary ? "#1a1a2e" : P.text,
        border: primary ? "none" : "1px solid " + P.border,
        padding: small ? "8px 16px" : "14px 32px",
        borderRadius: "50px",
        fontSize: small ? "13px" : "15px",
        fontWeight: primary ? "700" : "500",
        fontFamily: sans,
        letterSpacing: "0.04em",
        cursor: disabled ? "not-allowed" : "pointer",
        opacity: disabled ? 0.4 : 1,
        transition: "all 0.2s",
        ...style,
      }}
    >
      {children}
    </button>
  );
}
