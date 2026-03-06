import { P, sans } from '../data/constants.js';

export default function Chip({ active, children, onClick, small }) {
  return (
    <button
      onClick={onClick}
      role="option"
      aria-selected={active}
      style={{
        background: active ? P.grad : P.card,
        color: active ? "#1a1a2e" : P.text,
        border: "1px solid " + (active ? "transparent" : P.border),
        padding: small ? "7px 12px" : "10px 18px",
        borderRadius: "24px",
        fontSize: small ? "12px" : "14px",
        fontWeight: active ? "700" : "400",
        fontFamily: sans,
        cursor: "pointer",
        transition: "all 0.2s",
      }}
    >
      {children}
    </button>
  );
}
