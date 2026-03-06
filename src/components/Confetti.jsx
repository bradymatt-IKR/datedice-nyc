import { useEffect, useState } from 'react';

const COLORS = ['#e8c36a', '#c97d4a', '#d4727e', '#6ecf94', '#6aafe8', '#f5d98a'];
const SHAPES = ['circle', 'rect', 'star'];

function randomBetween(a, b) { return a + Math.random() * (b - a); }

export default function Confetti({ active }) {
  const [particles, setParticles] = useState([]);

  useEffect(() => {
    if (!active) { setParticles([]); return; }
    const p = Array.from({ length: 40 }, (_, i) => ({
      id: i,
      x: randomBetween(10, 90),
      color: COLORS[i % COLORS.length],
      shape: SHAPES[i % SHAPES.length],
      size: randomBetween(6, 12),
      delay: randomBetween(0, 0.4),
      duration: randomBetween(1.2, 2.2),
      drift: randomBetween(-60, 60),
      rotation: randomBetween(0, 360),
    }));
    setParticles(p);
    const t = setTimeout(() => setParticles([]), 2500);
    return () => clearTimeout(t);
  }, [active]);

  if (particles.length === 0) return null;

  return (
    <div aria-hidden="true" style={{ position: 'fixed', inset: 0, pointerEvents: 'none', zIndex: 100, overflow: 'hidden' }}>
      {particles.map((p) => (
        <div
          key={p.id}
          style={{
            position: 'absolute',
            left: `${p.x}%`,
            top: '-5%',
            width: p.size,
            height: p.shape === 'rect' ? p.size * 0.6 : p.size,
            background: p.color,
            borderRadius: p.shape === 'circle' ? '50%' : p.shape === 'star' ? '2px' : '1px',
            animation: `confettiFall ${p.duration}s ease-in ${p.delay}s both`,
            transform: `rotate(${p.rotation}deg) translateX(${p.drift}px)`,
            opacity: 0.9,
          }}
        />
      ))}
    </div>
  );
}
