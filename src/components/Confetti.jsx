import { useEffect, useState } from 'react';

const COLORS = ['#e8c36a', '#c97d4a', '#d4727e', '#6ecf94', '#6aafe8', '#f5d98a', '#ff9a76', '#ffd93d'];
const SHAPES = ['circle', 'rect', 'star', 'ribbon'];

function randomBetween(a, b) { return a + Math.random() * (b - a); }

export default function Confetti({ active }) {
  const [particles, setParticles] = useState([]);

  useEffect(() => {
    if (!active) { setParticles([]); return; }
    const p = Array.from({ length: 55 }, (_, i) => {
      const motionType = i < 18 ? 'fall' : i < 36 ? 'wobble' : 'spiral';
      return {
        id: i,
        x: randomBetween(5, 95),
        color: COLORS[i % COLORS.length],
        shape: SHAPES[i % SHAPES.length],
        size: randomBetween(6, 14),
        delay: randomBetween(0, 0.5),
        duration: randomBetween(1.0, 3.2),
        drift: randomBetween(-80, 80),
        rotation: randomBetween(0, 360),
        rotationSpeed: randomBetween(360, 1080),
        motionType,
      };
    });
    setParticles(p);
    const t = setTimeout(() => setParticles([]), 3500);
    return () => clearTimeout(t);
  }, [active]);

  if (particles.length === 0) return null;

  return (
    <div aria-hidden="true" style={{ position: 'fixed', inset: 0, pointerEvents: 'none', zIndex: 100, overflow: 'hidden' }}>
      {particles.map((p) => {
        const isRibbon = p.shape === 'ribbon';
        const w = isRibbon ? p.size * 0.35 : p.size;
        const h = isRibbon ? p.size * 2.2 : (p.shape === 'rect' ? p.size * 0.6 : p.size);
        const br = p.shape === 'circle' ? '50%' : p.shape === 'star' ? '2px' : '1px';
        const animName = p.motionType === 'spiral' ? 'confettiSpiral' : 'confettiFall';

        return (
          <div key={p.id} style={{ position: 'absolute', left: `${p.x}%`, top: '-5%' }}>
            <div style={{
              width: w, height: h,
              background: p.color,
              borderRadius: br,
              animation: `${animName} ${p.duration}s ease-in ${p.delay}s both` +
                (p.motionType === 'wobble' ? `, confettiWobbleX ${p.duration * 0.7}s ease-in-out ${p.delay}s infinite` : ''),
              transform: `rotate(${p.rotation}deg) translateX(${p.drift}px)`,
              opacity: 0.9,
            }} />
          </div>
        );
      })}
    </div>
  );
}
