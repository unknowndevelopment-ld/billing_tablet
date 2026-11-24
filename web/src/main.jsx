import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import './style.css';
import './controls.css';

const empty = { invoices: [], sent: [], currency: '$', canBill: true };
const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'billing_tablet';
const nui = async (name, data = {}) => {
  const response = await fetch(`https://${resource}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
  return response.json();
};

function App() {
  const [visible, setVisible] = useState(false);
  const [data, setData] = useState(empty);
  const [view, setView] = useState('invoices');
  const [notice, setNotice] = useState(null);
  const [busy, setBusy] = useState(false);
  const [clock, setClock] = useState('');
  const money = amount => `${data.currency}${Number(amount || 0).toLocaleString()}`;

  useEffect(() => {
    const message = event => {
      if (event.data?.action === 'open') { setVisible(true); setView('invoices'); setNotice(null); }
      if (event.data?.action === 'close') setVisible(false);
      if (event.data?.action === 'data') setData(event.data.data || empty);
    };
    const key = event => { if (event.key === 'Escape' || event.key === 'F7') nui('close'); };
    const tick = () => setClock(new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
    window.addEventListener('message', message);
    window.addEventListener('keydown', key);
    tick();
    const timer = setInterval(tick, 1000);
    return () => { window.removeEventListener('message', message); window.removeEventListener('keydown', key); clearInterval(timer); };
  }, []);

  async function act(name, payload) {
    setBusy(true);
    try {
      const result = await nui(name, payload);
      setNotice({ message: result.message, error: !result.ok });
      if (result.ok) nui('refresh');
      return result.ok;
    } catch {
      setNotice({ message: 'Request failed. Try again.', error: true });
      return false;
    } finally { setBusy(false); }
  }

  function rows(items, incoming) {
    if (!items.length) return <div className="empty"><strong>No invoices yet</strong>{incoming ? 'Bills sent to you will appear here.' : 'Your issued bills will appear here.'}</div>;
    return items.map(invoice => <div className="row" key={invoice.id}>
      <div className="icon">{incoming ? '↙' : '↗'}</div>
      <div className="details"><strong>{invoice.reason}</strong><span>{incoming ? `${invoice.job_label} · ${invoice.issuer_name}` : invoice.recipient_name} · #{invoice.id} · {invoice.created_at ? new Date(String(invoice.created_at).replace(' ', 'T')).toLocaleDateString() : ''}</span></div>
      <div className="price"><strong>{money(invoice.amount)}</strong><span className={`badge ${invoice.status}`}>{invoice.status.toUpperCase()}</span></div>
      {incoming && invoice.status === 'unpaid' && <button className="pay" disabled={busy} onClick={() => act('pay', { id: invoice.id })}>PAY</button>}
    </div>);
  }

  const unpaid = data.invoices.filter(item => item.status === 'unpaid');
  const titles = { invoices: ['My invoices', 'Review and settle your outstanding bills.'], sent: ['Issued invoices', 'Invoices you have sent.'], create: ['New invoice', 'Bill a nearby player from your job.'] };
  const switchView = next => { setView(next); setNotice(null); };

  return visible && <main id="tablet">
    <div className="camera" />
    <div className="screen">
      <header><div className="brand"><span className="mark">▣</span><div><strong>BILLING</strong><small>TABLET</small></div></div><div className="header-right"><span>{clock}</span><button className="close-button" aria-label="Close tablet" title="Close tablet" onClick={() => nui('close')}><span className="close-icon" aria-hidden="true" /><span>CLOSE</span></button></div></header>
      <div className="content">
        <aside>
          <div className="workspace">WORKSPACE <strong>{(data.job || 'Personal').toUpperCase()}</strong></div>
          {[['invoices', '▣', 'My invoices'], ['sent', '↗', 'Issued invoices'], ['create', '＋', 'New invoice']].map(([name, icon, label]) => <button key={name} className={`nav ${view === name ? 'active' : ''}`} onClick={() => switchView(name)}><span>{icon}</span>{label}{name === 'invoices' && <b>{unpaid.length}</b>}</button>)}
          <div className="side-bottom">Secure payments<br /><span>Powered by your bank account</span></div>
        </aside>
        <section className="page">
          <div className="page-top"><div><p className="eyebrow">FINANCE / {titles[view][0].toUpperCase()}</p><h1>{titles[view][0]}</h1><p>{titles[view][1]}</p></div><button className="refresh" onClick={() => nui('refresh')}>↻ Refresh</button></div>
          {notice && <div id="notice" className={notice.error ? 'error' : ''} role="status">{notice.message}</div>}
          {view === 'invoices' && <><div className="stats"><div><span>OUTSTANDING</span><strong>{money(unpaid.reduce((sum, item) => sum + Number(item.amount), 0))}</strong></div><div><span>UNPAID INVOICES</span><strong>{unpaid.length}</strong></div><div><span>TOTAL INVOICES</span><strong>{data.invoices.length}</strong></div></div><div className="panel"><div className="panel-head"><h2>Invoice history</h2><span>Latest 100</span></div>{rows(data.invoices, true)}</div></>}
          {view === 'sent' && <div className="panel"><div className="panel-head"><h2>Issued invoices</h2><span>Latest 100</span></div>{rows(data.sent, false)}</div>}
          {view === 'create' && <div className="panel form-panel"><p className="eyebrow">CREATE INVOICE</p><h2>Bill a nearby player</h2><p>Enter their server ID. They must be within 5 meters.</p><form onSubmit={async event => { event.preventDefault(); const form = event.currentTarget; if (await act('create', Object.fromEntries(new FormData(form)))) form.reset(); }}><label>PLAYER SERVER ID<input name="target" type="number" min="1" step="1" required placeholder="e.g. 24" /></label><label>AMOUNT<input name="amount" type="number" min="1" max={data.maxAmount || 100000} step="1" required placeholder="e.g. 500" /></label><label>REASON<input name="reason" maxLength="120" minLength="3" required placeholder="What is this invoice for?" /></label><button className="primary" type="submit" disabled={busy}>Send invoice <span>↗</span></button></form></div>}
        </section>
      </div>
      <footer><span>● SYSTEM ONLINE</span><span>ESC TO CLOSE · F7 TO TOGGLE</span></footer>
    </div>
  </main>;
}

createRoot(document.getElementById('root')).render(<App />);
