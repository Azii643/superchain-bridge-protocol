const plans = [
  { name: 'Free', price: '$0', description: 'For prototypes and small experiments', features: ['1k messages/month', 'Basic dashboard', 'Community support'] },
  { name: 'Pro', price: '$49', description: 'For product teams building cross-chain workflows', features: ['100k messages/month', 'API access', 'Analytics dashboards', 'Priority support'] },
  { name: 'Enterprise', price: 'Custom', description: 'For production-scale multi-chain operations', features: ['Private deployment', 'Custom routing', 'SLA and support', 'Dedicated onboarding'] },
];

export default function App() {
  return (
    <main className="page-shell">
      <header className="hero">
        <div className="eyebrow">Superchain · Bridge Protocol</div>
        <h1>Turn cross-chain messaging into a scalable product.</h1>
        <p>
          A tokenized, subscription-based cross-chain infrastructure platform for secure
          message routing, monitoring, and deployment automation.
        </p>
        <div className="cta-row">
          <button className="primary">Launch App</button>
          <button className="secondary">View Pricing</button>
        </div>
      </header>

      <section className="metrics">
        <div className="metric-card">
          <span className="label">Messages</span>
          <strong>1.2M</strong>
          <small>processed monthly</small>
        </div>
        <div className="metric-card">
          <span className="label">Active Teams</span>
          <strong>420</strong>
          <small>on paid plans</small>
        </div>
        <div className="metric-card">
          <span className="label">Revenue</span>
          <strong>$148k</strong>
          <small>monthly recurring</small>
        </div>
      </section>

      <section className="panel">
        <h2>Why teams choose this product</h2>
        <div className="feature-grid">
          <article>
            <h3>Secure cross-chain routing</h3>
            <p>Reliably move payloads across L2s with verifiable message execution.</p>
          </article>
          <article>
            <h3>Usage-aware pricing</h3>
            <p>Charge based on actual bridge activity and message throughput.</p>
          </article>
          <article>
            <h3>Token-backed incentives</h3>
            <p>Align ecosystems with staking, governance, and rewards.</p>
          </article>
        </div>
      </section>

      <section className="panel">
        <h2>Pricing</h2>
        <div className="pricing-grid">
          {plans.map(plan => (
            <article key={plan.name} className="plan-card">
              <h3>{plan.name}</h3>
              <div className="price">{plan.price}</div>
              <p>{plan.description}</p>
              <ul>
                {plan.features.map(feature => (
                  <li key={feature}>{feature}</li>
                ))}
              </ul>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
