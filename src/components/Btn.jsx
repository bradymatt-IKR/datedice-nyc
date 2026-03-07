import { useState } from 'react';
import { P, sans } from '../data/constants.js';

export default function Btn({ children, primary, small, disabled, style, ...props }) {
  const [hovered, setHovered] = useState(false);
  const [pressed, setPressed] = useState(false);

  const hoverTransform = hovered && !disabled ? 'translateY(-1px) scale(1.02)' : 'none';
  const activeTransform = pressed && !disabled ? 'translateY(0px) scale(0.98)' : hoverTransform;
  const hoverShadow = hovered && !disabled
    ? (primary ? '0 6px 24px rgba(232,195,106,0.35)' : '0 4px 16px rgba(0,0,0,0.3)')
    : 'none';

  return (
    <button
      {...props}
      disabled={disabled}
      aria-disabled={disabled || undefined}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => { setHovered(false); setPressed(false); }}
      onMouseDown={() => setPressed(true)}
      onMouseUp={() => setPressed(false)}
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
        transition: "all 0.2s cubic-bezier(0.4,0,0.2,1)",
        transform: activeTransform,
        boxShadow: pressed ? 'none' : hoverShadow,
        ...style,
      }}
    >
      {children}
    </button>
  );
}
