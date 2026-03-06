import { createRoot } from 'react-dom/client';
import ErrorBoundary from './components/ErrorBoundary.jsx';
import App from './App.jsx';
import './styles/index.css';

createRoot(document.getElementById('root')).render(
  <ErrorBoundary>
    <App />
  </ErrorBoundary>
);
