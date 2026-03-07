import { useState } from 'react';
import { P, sans } from '../data/constants.js';

const STEPS = [
  {
    title: "Set the Scene",
    desc: "Pick a vibe, budget, and neighborhood — or tap Dealer's Choice for a total surprise.",
    animClass: "onboardFilterPop",
    icons: ["✨", "💰", "📍", "🍽"],
  },
  {
    title: "Roll the Dice",
    desc: "Tap the dice and AI scours NYC for the perfect spot — with insider tips and booking links.",
    animClass: "onboardDiceBounce",
    icons: ["🎲"],
  },
  {
    title: "Lock It In",
    desc: "Love the pick? Lock it in, share with your date, and track your date history.",
    animClass: "onboardLockClick",
    icons: ["🔒"],
  },
];

export default function Onboarding({ onComplete }) {
  const [step, setStep] = useState(0);

  const next = () => {
    if (step < STEPS.length - 1) {
      setStep(step + 1);
    } else {
      onComplete();
    }
  };

  const skip = () => onComplete();

  const current = STEPS[step];

  return (
    <div style={{
      position: "fixed", inset: 0, zIndex: 300,
      background: "rgba(10,10,20,0.96)",
      backdropFilter: "blur(16px)",
      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
      padding: "40px 24px",
      animation: "onboardSlideIn 0.35s ease both",
    }}>
      {/* Icons area */}
      <div style={{
        display: "flex", gap: current.icons.length > 1 ? "12px" : "0",
        marginBottom: "32px",
      }}>
        {current.icons.map((icon, i) => (
          <div key={step + "-" + i} style={{
            fontSize: current.icons.length > 1 ? "36px" : "56px",
            animation: `${current.animClass} ${current.icons.length > 1 ? (0.5 + i * 0.12) + "s" : "0.8s"} ease both`,
            animationDelay: (i * 0.1) + "s",
          }} aria-hidden="true">
            {icon}
          </div>
        ))}
      </div>

      {/* Text */}
      <h2 key={"t" + step} style={{
        fontSize: "24px", fontWeight: "400", color: P.gold,
        margin: "0 0 12px", textAlign: "center",
        animation: "onboardSlideIn 0.3s ease both",
        animationDelay: "0.1s",
      }}>
        {current.title}
      </h2>
      <p key={"d" + step} style={{
        fontSize: "15px", color: P.textDim, fontFamily: sans,
        textAlign: "center", maxWidth: "320px", margin: "0 0 48px",
        lineHeight: 1.6,
        animation: "onboardSlideIn 0.3s ease both",
        animationDelay: "0.15s",
      }}>
        {current.desc}
      </p>

      {/* Dot indicators */}
      <div style={{ display: "flex", gap: "8px", marginBottom: "32px" }}>
        {STEPS.map((_, i) => (
          <div key={i} style={{
            width: i === step ? "24px" : "8px",
            height: "8px",
            borderRadius: "4px",
            background: i === step ? P.gold : "rgba(255,255,255,0.15)",
            transition: "all 0.3s cubic-bezier(0.4,0,0.2,1)",
          }} />
        ))}
      </div>

      {/* Buttons */}
      <div style={{ display: "flex", gap: "16px", alignItems: "center" }}>
        <button onClick={skip} style={{
          background: "none", border: "none", color: P.textDim, fontSize: "14px",
          fontFamily: sans, cursor: "pointer", padding: "10px 20px",
        }}>
          Skip
        </button>
        <button onClick={next} style={{
          background: P.grad, color: "#1a1a2e", border: "none",
          borderRadius: "50px", padding: "12px 36px", fontSize: "15px",
          fontWeight: "700", fontFamily: sans, cursor: "pointer",
          boxShadow: "0 4px 20px rgba(232,195,106,0.3)",
          transition: "transform 0.15s, box-shadow 0.15s",
        }}
          onMouseDown={(e) => { e.currentTarget.style.transform = "scale(0.97)"; }}
          onMouseUp={(e) => { e.currentTarget.style.transform = "scale(1)"; }}
          onMouseLeave={(e) => { e.currentTarget.style.transform = "scale(1)"; }}
        >
          {step < STEPS.length - 1 ? "Next" : "Let's Roll!"}
        </button>
      </div>
    </div>
  );
}
