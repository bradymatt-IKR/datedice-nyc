import { Component } from 'react';
import { P, sans, serif } from '../data/constants.js';

export default class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, info) {
    console.error('DateDice error:', error, info.componentStack);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div role="alert" style={{
          minHeight: '100vh',
          background: P.bg,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '40px 20px',
          textAlign: 'center',
        }}>
          <div style={{ fontSize: '64px', marginBottom: '16px' }}>🎲</div>
          <h1 style={{ fontFamily: serif, fontSize: '28px', color: P.gold, fontWeight: '400', margin: '0 0 12px' }}>
            Something went wrong
          </h1>
          <p style={{ fontFamily: sans, fontSize: '15px', color: P.textDim, margin: '0 0 8px', maxWidth: '400px', lineHeight: 1.6 }}>
            The dice hit a snag. This usually fixes itself with a quick refresh.
          </p>
          {this.state.error && (
            <p style={{ fontFamily: sans, fontSize: '12px', color: P.accent, margin: '0 0 24px', maxWidth: '400px' }}>
              {this.state.error.message}
            </p>
          )}
          <button
            onClick={() => window.location.reload()}
            style={{
              background: P.grad,
              color: '#1a1a2e',
              border: 'none',
              padding: '14px 40px',
              borderRadius: '50px',
              fontSize: '15px',
              fontWeight: '700',
              fontFamily: sans,
              cursor: 'pointer',
              letterSpacing: '0.04em',
            }}
          >
            Try Again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
