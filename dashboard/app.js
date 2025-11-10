(function(){
  const $ = id=>document.getElementById(id);
  const fmtPct = (v,d=2)=> v==null? '—' : `${v.toFixed(d)}%`;
  const fmtUsd = v=> v==null? '—' : `$${v.toLocaleString(undefined,{minimumFractionDigits:2, maximumFractionDigits:2})}`;
  const stateUrl = './data/state.json';
  const historyUrl = './data/history.json';
  const locales = { it:'./locale/it.json', en:'./locale/en.json', es:'./locale/es.json' };
  let localeData = {}; let currentLang = 'it';

  async function loadLocale(lang){
    try{ const r = await fetch(locales[lang]); localeData = await r.json(); currentLang = lang; applyLocale(); }
    catch(e){ console.warn('Locale load failed',lang,e); }
  }
  function t(key){ return (localeData[key]||document.querySelector(`[data-i18n="${key}"]`)?.textContent||key); }
  function applyLocale(){
    document.documentElement.setAttribute('lang', currentLang);
    document.querySelectorAll('[data-i18n]').forEach(el=>{ const k = el.getAttribute('data-i18n'); if(localeData[k]) el.textContent = localeData[k]; });
    // aria labels
    document.querySelectorAll('[data-i18n-aria]').forEach(el=>{ const k = el.getAttribute('data-i18n-aria'); if(localeData[k]) el.setAttribute('aria-label', localeData[k]); });
  }
  document.addEventListener('click',e=>{ const btn = e.target.closest('[data-lang-switch]'); if(btn){ loadLocale(btn.getAttribute('data-lang-switch')); }});

  function badge(status){
    switch(status){
      case 'ok': return t('badge_ok')||'OK';
      case 'warn': return t('badge_warn')||'WARN';
      case 'crit': return t('badge_crit')||'CRITICO';
      default: return '—';
    }
  }
  function setCardStatus(id,status){ const card = document.getElementById(id); if(card){ card.setAttribute('data-status',status); const b = card.querySelector('.badge'); if(b) b.textContent = badge(status); }}

  function evaluateStatuses(data){
    // TRE
    const tre = data.ethics.TRE_current; const treTarget = data.ethics.TRE_target;
    setCardStatus('card-tre', tre >= treTarget ? 'ok' : (tre >= treTarget*0.7 ? 'warn':'crit'));
    // ISF
    const isf = data.ethics.ISF; setCardStatus('card-isf', isf >= 90 ? 'ok' : (isf >= 75 ? 'warn':'crit'));
    // PV
    const pv = data.ethics.PV; setCardStatus('card-pv', pv < 1.0 ? 'ok' : (pv < 3.0 ? 'warn':'crit'));
    // RA
    const ra = data.ethics.RA_SA07; setCardStatus('card-ra', ra >= 0 ? 'ok' : (ra > -10 ? 'warn':'crit'));
    // Price
    const price = data.finance.sain_price; const floor = data.finance.price_floor; setCardStatus('card-price', price>=floor*1.05? 'ok': (price>=floor? 'warn':'crit'));
    // Fee
    const fee = data.finance.stabilization_fee; setCardStatus('card-fee', fee<=0.15? 'ok': (fee<=0.25? 'warn':'crit'));
  }

  function renderHistory(history){
    drawLineChart('chart-tre', history.labels, history.TRE, '#22c55e');
    drawLineChart('chart-isf', history.labels, history.ISF, '#38bdf8');
    drawLineChart('chart-pv', history.labels, history.PV, '#f59e0b');
  }

  function drawLineChart(canvasId, labels, values, stroke){
    const c = document.getElementById(canvasId); if(!c) return; const ctx = c.getContext('2d');
    const W = c.width = c.clientWidth - 2; const H = c.height = c.getAttribute('height');
    ctx.clearRect(0,0,W,H); ctx.lineWidth = 2; ctx.strokeStyle = stroke; ctx.beginPath();
    const min = Math.min(...values); const max = Math.max(...values); const pad = 8; const range = (max-min)||1;
    values.forEach((v,i)=>{ const x = pad + (W-2*pad)*(i/(values.length-1)); const y = H - pad - (H-2*pad)*((v-min)/range); if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y); });
    ctx.stroke();
    ctx.fillStyle = '#aeb8e0'; ctx.font = '10px system-ui';
    labels.forEach((lab,i)=>{ if(i%Math.ceil(labels.length/6)===0){ const x = pad + (W-2*pad)*(i/(labels.length-1)); ctx.fillText(lab, x-10, H-2); }});
  }

  async function load(){
    let data; try{ const r = await fetch(stateUrl,{cache:'no-store'}); data = await r.json(); } catch(e){ console.warn('State load fallback',e); data = {
      meta:{last_update_utc:new Date().toISOString(), network:'SAIN / Euystacio'},
      ethics:{TRE_current:0.15,TRE_target:0.30,ISF:70.8,PV:4.6,RA_SA07:5.0,moe:{peso_scarsita_change_pct:40}},
      finance:{sain_price:10.72,price_floor:10.0,stabilization_fee:0.10,fee_split:{restitution_fund:0.40,counter_cyclicity_fund:0.30,burn:0.30},fc_balance_usd:120000,proactive_defense_threshold:10.50},
      governance:{last_vote:'MOE Ricalibrazione (+40%)',votes_yes:9,votes_no:0,guardian_multisig:'7-of-9',audit_efa_status:'launched'},
      events:[
        {ts:new Date().toISOString(), msg:'GGC VOTO APPROVATO (9/9): Ordine di Ricalibrazione MOE eseguito.'},
        {ts:new Date().toISOString(), msg:'MOE PARAMETER UPDATE: Peso_Scarsità +40%.'},
        {ts:new Date().toISOString(), msg:'AIC RESPONSE: Allocazione avviata su PeaceBond SA-07 Water (RA +5%).'},
        {ts:new Date().toISOString(), msg:'AUDIT EFA lanciato: dati sottoposti a verifica crittografica.'}
      ]
    }; }

    let history; try{ const h = await fetch(historyUrl,{cache:'no-store'}); history = await h.json(); } catch(e){ history = { labels:['T-5','T-4','T-3','T-2','T-1','Now'], TRE:[0.11,0.12,0.13,0.14,0.145,0.15], ISF:[68,69,70,70.2,70.5,70.8], PV:[5.2,5.1,5.0,4.9,4.7,4.6] }; }

    // Populate text
    $('last-updated').textContent = `${t('last_update_label')} ${new Date(data.meta.last_update_utc).toLocaleString()}`;
    $('network-name').textContent = `${t('network_label')} ${data.meta.network}`;
    $('tre-current').textContent = fmtPct(data.ethics.TRE_current,2);
    $('tre-target').textContent = fmtPct(data.ethics.TRE_target,2);
    $('isf').textContent = (data.ethics.ISF??'—');
    $('pv').textContent = fmtPct(data.ethics.PV,1);
    $('ra-sa07').textContent = fmtPct(data.ethics.RA_SA07,1);
    $('sain-price').textContent = fmtUsd(data.finance.sain_price);
    $('price-floor').textContent = fmtUsd(data.finance.price_floor);
    $('stabilization-fee').textContent = fmtPct(data.finance.stabilization_fee*100,2);
    $('fee-split').textContent = `Restitution 40% • FC 30% • Burn 30%`;
    $('moe-change').textContent = `Peso Scarsità +${data.ethics.moe.peso_scarsita_change_pct}%`;
    $('ggc-vote').textContent = `${data.governance.last_vote} — Esito: ${data.governance.votes_yes} Sì, ${data.governance.votes_no} No`;
    $('multisig').textContent = data.governance.guardian_multisig;
    $('audit-status').textContent = `Stato: ${data.governance.audit_efa_status}`;
    $('defense-threshold').textContent = fmtUsd(data.finance.proactive_defense_threshold);
    $('fc-balance').textContent = fmtUsd(data.finance.fc_balance_usd);

    const eventsOl = $('events'); eventsOl.innerHTML='';
    (data.events||[]).slice(0,10).forEach(ev=>{ const li=document.createElement('li'); const tEl=document.createElement('time'); tEl.textContent = `[${new Date(ev.ts).toLocaleString()}]`; const span=document.createElement('span'); span.textContent = ' '+ ev.msg; li.appendChild(tEl); li.appendChild(span); eventsOl.appendChild(li); });

    evaluateStatuses(data);
    renderHistory(history);
  }

  loadLocale('it').then(load);
})();
