import { useState, useEffect, useRef } from 'react';
import { DICE_DOTS } from '../data/constants.js';

function DiceFaceSVG({ v, size }) {
  return (
    <svg viewBox="0 0 100 100" width={size} height={size} style={{ display: 'block' }}>
      <defs>
        <linearGradient id={"dg" + v} x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="rgba(255,253,235,1)" />
          <stop offset="100%" stopColor="rgba(242,230,195,1)" />
        </linearGradient>
      </defs>
      <rect x="3" y="3" width="94" height="94" rx="19" fill={"url(#dg" + v + ")"} stroke="rgba(190,148,58,0.3)" strokeWidth="1.5" />
      {(DICE_DOTS[v] || DICE_DOTS[1]).map((p, i) => (
        <g key={i}>
          <circle cx={p[0]} cy={p[1] + 1} r="9" fill="rgba(0,0,0,0.18)" />
          <circle cx={p[0]} cy={p[1]} r="9" fill="#1b1408" />
        </g>
      ))}
    </svg>
  );
}

export default function Dice3D({ value, rolling, size }) {
  const s = size || 80;
  const h = s / 2;
  const [phase, setPhase] = useState('idle');
  const prevRolling = useRef(false);
  const timerRef = useRef(null);

  useEffect(() => {
    if (rolling && !prevRolling.current) {
      if (timerRef.current) clearTimeout(timerRef.current);
      setPhase('rolling');
    } else if (!rolling && prevRolling.current) {
      if (timerRef.current) clearTimeout(timerRef.current);
      setPhase('settling');
      timerRef.current = setTimeout(() => setPhase('idle'), 1200);
    }
    prevRolling.current = rolling;
    return () => { if (timerRef.current) clearTimeout(timerRef.current); };
  }, [rolling]);

  const front = value || 1;
  const back = 7 - front;
  const sides = [1, 2, 3, 4, 5, 6].filter((x) => x !== front && x !== back);
  const faces = { front, back, right: sides[0], left: sides[1], top: sides[2], bottom: sides[3] };

  const fb = { position: 'absolute', width: s, height: s, backfaceVisibility: 'hidden', WebkitBackfaceVisibility: 'hidden' };
  const cubeAnim = phase === 'rolling' ? 'diceRotate 0.65s linear infinite' : phase === 'settling' ? 'diceSettle 1.15s cubic-bezier(0.12,0,0.2,1) forwards' : 'none';
  const cubeTransform = (phase === 'rolling' || phase === 'settling') ? undefined : 'rotateX(0deg) rotateY(0deg)';
  const floatAnim = phase === 'rolling' ? 'diceFloat 0.38s ease-in-out infinite alternate' : 'none';
  const floatTransform = phase === 'rolling' ? undefined : 'translateY(0px)';

  return (
    <div role="img" aria-label={`Dice showing ${value || 1}`} style={{ width: s, height: s, position: 'relative' }}>
      <div style={{ position: 'absolute', bottom: '-6px', left: '50%', transform: 'translateX(-50%)', width: s * 0.75, height: '10px', background: 'radial-gradient(ellipse, rgba(232,195,106,0.5) 0%, transparent 70%)', borderRadius: '50%', opacity: phase === 'idle' ? 1 : 0, transition: 'opacity 0.5s' }} />
      <div style={{ width: s, height: s, animation: floatAnim, transform: floatTransform, transition: phase !== 'rolling' ? 'transform 0.35s ease-out' : undefined }}>
        <div style={{ width: s, height: s, perspective: s * 4 }}>
          <div style={{ width: s, height: s, position: 'relative', transformStyle: 'preserve-3d', animation: cubeAnim, transform: cubeTransform }}>
            <div style={{ ...fb, transform: 'translateZ(' + h + 'px)' }}><DiceFaceSVG v={faces.front} size={s} /></div>
            <div style={{ ...fb, transform: 'rotateY(180deg) translateZ(' + h + 'px)' }}><DiceFaceSVG v={faces.back} size={s} /></div>
            <div style={{ ...fb, transform: 'rotateY(90deg) translateZ(' + h + 'px)' }}><DiceFaceSVG v={faces.right} size={s} /></div>
            <div style={{ ...fb, transform: 'rotateY(-90deg) translateZ(' + h + 'px)' }}><DiceFaceSVG v={faces.left} size={s} /></div>
            <div style={{ ...fb, transform: 'rotateX(90deg) translateZ(' + h + 'px)' }}><DiceFaceSVG v={faces.top} size={s} /></div>
            <div style={{ ...fb, transform: 'rotateX(-90deg) translateZ(' + h + 'px)' }}><DiceFaceSVG v={faces.bottom} size={s} /></div>
          </div>
        </div>
      </div>
    </div>
  );
}
