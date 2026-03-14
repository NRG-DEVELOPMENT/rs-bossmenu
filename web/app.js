
const app = document.getElementById('app')
const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'rs-bossmenu'

const dom = {
  shell: document.getElementById('bossShell'),
  dutyShell: document.getElementById('dutyShell'),
  jobTitle: document.getElementById('jobTitle'),
  heroTitle: document.getElementById('heroTitle'),
  heroSubtitle: document.getElementById('heroSubtitle'),
  providerBadge: document.getElementById('providerBadge'),
  dutyOverview: document.getElementById('dutyOverview'),
  sidebarSubtitle: document.getElementById('sidebarSubtitle'),
  statBalance: document.getElementById('statBalance'),
  statEmployees: document.getElementById('statEmployees'),
  statOnline: document.getElementById('statOnline'),
  activityPreview: document.getElementById('activityPreview'),
  activityList: document.getElementById('activityList'),
  employeeList: document.getElementById('employeeList'),
  nearbyList: document.getElementById('nearbyList'),
  employeeSearch: document.getElementById('employeeSearch'),
  employeeSort: document.getElementById('employeeSort'),
  quickGrid: document.getElementById('quickGrid'),
  quickAmount: document.getElementById('quickAmount'),
  heroPills: document.getElementById('heroPills'),
  dutyMeta: document.getElementById('dutyMeta'),
  stashBtn: document.getElementById('stashBtn'),
  wardrobeBtn: document.getElementById('wardrobeBtn'),
  dutyBtn: document.getElementById('dutyBtn'),
  financeChart: document.getElementById('financeChart'),
  financeLegend: document.getElementById('financeLegend'),
  financeNet: document.getElementById('financeNet'),
  modal: document.getElementById('actionModal'),
  modalTitle: document.getElementById('modalTitle'),
  modalSubtitle: document.getElementById('modalSubtitle'),
  modalBody: document.getElementById('modalBody'),
  modalConfirm: document.getElementById('modalConfirm'),
  dutyJobTitle: document.getElementById('dutyJobTitle'),
  dutyStatusBadge: document.getElementById('dutyStatusBadge'),
  dutyStatusText: document.getElementById('dutyStatusText'),
  dutyTotal: document.getElementById('dutyTotal'),
  dutyCurrent: document.getElementById('dutyCurrent'),
  dutyDays: document.getElementById('dutyDays'),
  dutyToggleBtn: document.getElementById('dutyToggleBtn'),
}

let state = {
  job: null,
  jobLabel: '',
  employees: [],
  nearby: [],
  activity: [],
  quickAmounts: [500, 1000, 2500, 5000],
  balance: 0,
  employeeCount: 0,
  onlineCount: 0,
  operations: {},
  financeHistory: [],
  grades: [],
  dutyOverview: [],
}

let dutyState = null
let currentView = 'boss'
let modalState = null

function post(action, payload = {}) {
  return fetch(`https://${resource}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload)
  }).then(r => r.json())
}

function fmtMoney(value) {
  return `$${new Intl.NumberFormat('en-US').format(Number(value || 0))}`
}

function initials(name = '') {
  return name.split(' ').filter(Boolean).slice(0, 2).map(v => v[0]?.toUpperCase() || '').join('') || 'NA'
}

function formatGradeLabel(grade) {
  const match = (state.grades || []).find(item => Number(item.grade) === Number(grade))
  return match ? `${match.label} • Grade ${match.grade}` : `Grade ${grade}`
}

function showTab(tab) {
  document.querySelectorAll('.nav-btn').forEach(btn => btn.classList.toggle('active', btn.dataset.tab === tab))
  document.querySelectorAll('.tab').forEach(panel => panel.classList.toggle('active', panel.id === `tab-${tab}`))
}

function showView(view) {
  currentView = view
  app.classList.remove('hidden')
  dom.shell.classList.toggle('hidden', view !== 'boss')
  dom.dutyShell.classList.toggle('hidden', view !== 'duty')
  if (view !== 'boss') closeModal(false)
}

function renderHeroPills() {
  dom.heroPills.innerHTML = [
    { label: 'Balance', value: fmtMoney(state.balance) },
    { label: 'Employees', value: state.employeeCount },
    { label: 'Online', value: state.onlineCount },
  ].map(item => `
    <div class="hero-pill">
      <span class="eyebrow">${item.label}</span>
      <strong>${item.value}</strong>
    </div>
  `).join('')
}

function renderQuickButtons() {
  dom.quickGrid.innerHTML = state.quickAmounts.map(amount => `
    <button class="chip-btn" onclick="setQuickAmount(${amount})">${fmtMoney(amount)}</button>
  `).join('')
}

function normalizeEmployees() {
  const query = (dom.employeeSearch.value || '').trim().toLowerCase()
  const sort = dom.employeeSort.value || 'default'
  let rows = [...(state.employees || [])]

  if (query) {
    rows = rows.filter(emp =>
      String(emp.name || '').toLowerCase().includes(query) ||
      String(emp.gradeLabel || '').toLowerCase().includes(query) ||
      String(emp.identifier || '').toLowerCase().includes(query)
    )
  }

  if (sort === 'name') {
    rows.sort((a, b) => String(a.name).localeCompare(String(b.name)))
  } else if (sort === 'grade') {
    rows.sort((a, b) => Number(b.grade || 0) - Number(a.grade || 0))
  } else if (sort === 'online') {
    rows.sort((a, b) => Number(Boolean(b.online)) - Number(Boolean(a.online)))
  }

  return rows
}

function renderEmployees() {
  const totals = Object.fromEntries((state.dutyOverview || []).map(item => [item.identifier, item]))
  const rows = normalizeEmployees().map(emp => ({ ...emp, ...(totals[emp.identifier] || {}) }))
  dom.employeeList.innerHTML = rows.length ? rows.map(emp => `
    <article class="employee-card">
      <div class="employee-head">
        <div class="employee-user">
          <div class="avatar">${initials(emp.name)}</div>
          <div>
            <div class="employee-name">${emp.name}</div>
            <div class="employee-sub">${emp.gradeLabel} • Grade ${emp.grade}</div>
            <div class="subtle">Hours worked: ${emp.totalFormatted || '0m'}</div>
          </div>
        </div>
        <div class="status ${emp.online ? 'online' : 'offline'}">${emp.online ? 'Online' : 'Offline'}</div>
      </div>
      <div class="employee-actions">
        <button class="employee-action" onclick="employeeAction('promote','${emp.identifier}')">Promote</button>
        <button class="employee-action" onclick="employeeAction('demote','${emp.identifier}')">Demote</button>
        <button class="employee-action" onclick="employeeAction('bonus','${emp.identifier}')">Bonus</button>
        <button class="employee-action fire" onclick="quickEmployeeAction('fire','${emp.identifier}')">Fire</button>
      </div>
    </article>
  `).join('') : `<div class="empty">No employees found.</div>`
}

function renderNearby() {
  const rows = state.nearby || []
  dom.nearbyList.innerHTML = rows.length ? rows.map(player => `
    <div class="list-card">
      <div>
        <div class="list-title">${player.name}</div>
        <div class="list-meta">Distance ${Number(player.distance).toFixed(1)}m</div>
      </div>
      <button class="hire-btn" onclick="hirePlayer(${player.source})">Hire</button>
    </div>
  `).join('') : `<div class="empty">No nearby players available.</div>`
}

function renderActivity(target, items) {
  target.innerHTML = items.length ? items.map(item => `
    <div class="list-card">
      <div>
        <div class="list-title">${item.title || 'System'}</div>
        <div class="list-meta">${item.description || ''}</div>
      </div>
      <div class="subtle">${item.timestamp || ''}</div>
    </div>
  `).join('') : `<div class="empty">No recent activity yet.</div>`
}

function renderDutyOverview() {
  const rows = state.dutyOverview || []
  dom.dutyOverview.innerHTML = rows.length ? rows.map(item => `
    <div class="list-card duty-card">
      <div>
        <div class="list-title">${item.name}</div>
        <div class="list-meta">${item.gradeLabel} • Total ${item.totalFormatted} • Current ${item.currentShiftFormatted || '0m'}</div>
        <div class="duty-card-days">
          ${(item.days || []).map(day => `
            <div class="duty-mini-day ${day.today ? 'today' : ''}">
              <span>${day.short || day.day.slice(0, 3)}</span>
              <strong>${day.formatted}</strong>
            </div>
          `).join('')}
        </div>
      </div>
      <div class="status ${item.online ? 'online' : 'offline'}">${item.online ? 'Online' : 'Offline'}</div>
    </div>
  `).join('') : '<div class="empty">No duty logs yet.</div>'
}

function renderOperations() {
  const ops = state.operations || {}
  dom.dutyMeta.textContent = ops.duty
    ? `Current status: ${ops.onDuty ? 'On Duty' : 'Off Duty'}`
    : 'Duty control is unavailable on this framework.'

  dom.stashBtn.disabled = !ops.stash
  dom.wardrobeBtn.disabled = !ops.wardrobe
  dom.dutyBtn.disabled = !ops.duty
  dom.dutyBtn.textContent = ops.duty ? (ops.onDuty ? 'Go Off Duty' : 'Go On Duty') : 'Duty Unavailable'
}

function renderFinanceChart() {
  const points = Array.isArray(state.financeHistory) ? state.financeHistory : []
  const svg = dom.financeChart
  if (!svg) return

  if (!points.length) {
    svg.innerHTML = ''
    dom.financeLegend.innerHTML = '<span class="subtle">No finance data yet.</span>'
    dom.financeNet.textContent = 'No data'
    return
  }

  const width = 820
  const height = 260
  const padX = 26
  const topPad = 26
  const bottomPad = 40
  const values = points.map(p => Number(p.amount || 0))
  const peak = Math.max(...values.map(v => Math.abs(v)), 1)
  const zeroY = topPad + ((height - topPad - bottomPad) * (peak / (peak * 2)))
  const step = points.length > 1 ? (width - padX * 2) / (points.length - 1) : 0
  const coords = points.map((point, index) => {
    const x = padX + (step * index)
    const normalized = (Number(point.amount || 0) / (peak * 2))
    const y = zeroY - normalized * (height - topPad - bottomPad)
    return { x, y, label: point.label || 'Now', amount: Number(point.amount || 0) }
  })

  const polyline = coords.map(point => `${point.x},${point.y}`).join(' ')
  const area = `${padX},${height - bottomPad} ${polyline} ${coords[coords.length - 1].x},${height - bottomPad}`
  const net = values.reduce((sum, value) => sum + value, 0)
  dom.financeNet.textContent = `${net >= 0 ? '+' : '-'}${fmtMoney(Math.abs(net))}`

  svg.innerHTML = `
    <defs>
      <linearGradient id="financeFill" x1="0" x2="0" y1="0" y2="1">
        <stop offset="0%" stop-color="rgba(120,169,255,0.38)"></stop>
        <stop offset="100%" stop-color="rgba(98,237,255,0.04)"></stop>
      </linearGradient>
    </defs>
    <line x1="${padX}" y1="${zeroY}" x2="${width - padX}" y2="${zeroY}" class="chart-zero"></line>
    <polygon points="${area}" fill="url(#financeFill)"></polygon>
    <polyline points="${polyline}" class="chart-line"></polyline>
    ${coords.map(point => `<circle cx="${point.x}" cy="${point.y}" r="5" class="chart-point"></circle>`).join('')}
    ${coords.map(point => `<text x="${point.x}" y="${height - 12}" text-anchor="middle" class="chart-label">${point.label}</text>`).join('')}
  `

  dom.financeLegend.innerHTML = coords.slice(-4).map(point => `
    <div class="legend-card">
      <span>${point.label}</span>
      <strong class="${point.amount >= 0 ? 'pos' : 'neg'}">${point.amount >= 0 ? '+' : '-'}${fmtMoney(Math.abs(point.amount))}</strong>
    </div>
  `).join('')
}

function render(data) {
  state = data || state
  dom.jobTitle.textContent = `${state.jobLabel || state.job || 'Boss'} Menu`
  dom.heroTitle.textContent = `${state.jobLabel || state.job || 'Boss'} Executive Control`
  dom.heroSubtitle.textContent = state.subtitle || 'Run society finance, staffing, and operations from one premium control panel.'
  dom.sidebarSubtitle.textContent = state.subtitle || 'Executive management dashboard'
  dom.providerBadge.textContent = 'Society Treasury'
  dom.statBalance.textContent = fmtMoney(state.balance)
  dom.statEmployees.textContent = state.employeeCount || 0
  dom.statOnline.textContent = state.onlineCount || 0
  renderHeroPills()
  renderQuickButtons()
  renderEmployees()
  renderNearby()
  renderActivity(dom.activityPreview, state.activity || [])
  renderActivity(dom.activityList, state.activity || [])
  renderOperations()
  renderDutyOverview()
  renderFinanceChart()
}

function renderDutyScreen(data) {
  dutyState = data
  dom.dutyJobTitle.textContent = `${data.label || data.job || 'Duty'} Time Sheet`
  dom.dutyStatusBadge.textContent = data.onDuty ? 'On Duty' : 'Off Duty'
  dom.dutyStatusBadge.className = `provider-chip ${data.onDuty ? 'chip-online' : 'chip-offline'}`
  dom.dutyStatusText.textContent = data.onDuty
    ? 'You are currently clocked in. Your shift time is being tracked live.'
    : 'Clock in when you start your shift to begin time tracking.'
  dom.dutyTotal.textContent = data.summary?.totalFormatted || '0m'
  dom.dutyCurrent.textContent = data.summary?.currentShiftFormatted || '0m'

  const toggleBtn = document.getElementById('dutyToggleBtn')
  if (toggleBtn) {
    toggleBtn.textContent = data.onDuty ? 'Go Off Duty' : 'Go On Duty'
    toggleBtn.className = `primary-btn duty-main-toggle ${data.onDuty ? 'is-off' : 'is-on'}`
  }

  const days = data.summary?.days || []
  const todayName = data.summary?.todayName
  dom.dutyDays.innerHTML = days.length ? days.map(day => {
    const isToday = day.day === todayName
    return `
      <article class="weekday-row ${isToday ? 'today' : ''}">
        <div class="weekday-row-main">
          <div class="weekday-row-daywrap">
            <div class="weekday-row-day">${day.day}</div>
            <div class="weekday-row-sub">${isToday ? 'Today' : 'Tracked time'}</div>
          </div>
          <div class="weekday-row-time">${day.formatted}</div>
        </div>
        ${isToday ? `<div class="weekday-row-badge ${data.onDuty ? 'online' : 'offline'}">${data.onDuty ? 'Active Shift' : 'Ready to Clock In'}</div>` : ''}
      </article>
    `
  }).join('') : `<div class="empty">No logged shifts yet.</div>`
}

function closeModal(push = true) {
  modalState = null
  dom.modal.classList.remove('open')
  dom.modalBody.innerHTML = ''
  if (push) document.activeElement?.blur?.()
}

function employeeByIdentifier(identifier) {
  return (state.employees || []).find(emp => emp.identifier === identifier)
}

function openModal(config) {
  modalState = config
  dom.modalTitle.textContent = config.title
  dom.modalSubtitle.textContent = config.subtitle || ''
  dom.modalConfirm.textContent = config.confirmText || 'Submit'
  dom.modalBody.innerHTML = config.body
  dom.modal.classList.add('open')
}

function buildGradeOptions(selected) {
  return (state.grades || []).map(grade => `
    <option value="${grade.grade}" ${Number(selected) === Number(grade.grade) ? 'selected' : ''}>${grade.label} • Grade ${grade.grade}</option>
  `).join('')
}

window.employeeAction = (action, identifier) => {
  const employee = employeeByIdentifier(identifier)
  if (!employee) return

  if (action === 'bonus') {
    openModal({
      title: `Pay Bonus to ${employee.name}`,
      subtitle: `This payment is taken from society funds.`,
      confirmText: 'Send Bonus',
      body: `
        <div class="modal-form">
          <label class="modal-field">
            <span>Employee</span>
            <input type="text" value="${employee.name} • ${employee.gradeLabel}" disabled />
          </label>
          <label class="modal-field">
            <span>Bonus Amount</span>
            <input id="modalBonusAmount" type="number" min="1" placeholder="Enter amount" />
          </label>
        </div>
      `,
      onConfirm: () => {
        const amount = document.getElementById('modalBonusAmount')?.value
        return post('action', { action: 'bonus', identifier, amount, job: state.job })
      }
    })
    return
  }

  if (action === 'promote' || action === 'demote') {
    const direction = action === 'promote' ? 1 : -1
    const defaultGrade = Math.max(0, Number(employee.grade || 0) + direction)
    openModal({
      title: `${action === 'promote' ? 'Promote' : 'Demote'} ${employee.name}`,
      subtitle: `Choose the grade you want to assign.`,
      confirmText: action === 'promote' ? 'Confirm Promotion' : 'Confirm Demotion',
      body: `
        <div class="modal-form">
          <label class="modal-field">
            <span>Employee</span>
            <input type="text" value="${employee.name} • ${employee.gradeLabel}" disabled />
          </label>
          <label class="modal-field">
            <span>New Grade</span>
            <select id="modalGradeSelect">${buildGradeOptions(defaultGrade)}</select>
          </label>
        </div>
      `,
      onConfirm: () => {
        const grade = document.getElementById('modalGradeSelect')?.value
        return post('action', { action, identifier, grade, job: state.job })
      }
    })
  }
}

window.toggleDutyFromWeek = () => post('action', { action: 'duty', job: dutyState?.job || state.job })

window.quickEmployeeAction = (action, identifier) => {
  post('action', { action, identifier, job: state.job })
}

window.hirePlayer = target => {
  post('action', { action: 'hire', target, job: state.job })
}

window.setQuickAmount = amount => {
  dom.quickAmount.value = amount
  document.querySelectorAll('.chip-btn').forEach(btn => btn.classList.toggle('active', btn.textContent === fmtMoney(amount)))
}

document.querySelectorAll('.nav-btn').forEach(btn => btn.addEventListener('click', () => showTab(btn.dataset.tab)))
dom.employeeSearch.addEventListener('input', renderEmployees)
dom.employeeSort.addEventListener('change', renderEmployees)
document.getElementById('closeBtn').addEventListener('click', () => post('close'))
document.getElementById('dutyCloseBtn').addEventListener('click', () => post('close'))
document.getElementById('dutyToggleBtn').addEventListener('click', () => post('action', { action: 'duty', job: dutyState?.job || state.job }))
document.getElementById('depositBtn').addEventListener('click', () => post('action', { action: 'deposit', amount: document.getElementById('depositAmount').value, job: state.job }))
document.getElementById('withdrawBtn').addEventListener('click', () => post('action', { action: 'withdraw', amount: document.getElementById('withdrawAmount').value, job: state.job }))
document.getElementById('quickDepositBtn').addEventListener('click', () => post('action', { action: 'deposit', amount: dom.quickAmount.value, job: state.job }))
document.getElementById('quickWithdrawBtn').addEventListener('click', () => post('action', { action: 'withdraw', amount: dom.quickAmount.value, job: state.job }))
document.getElementById('refreshNearbyBtn').addEventListener('click', () => post('action', { action: 'refresh', job: state.job }))
dom.stashBtn.addEventListener('click', () => post('action', { action: 'stash', job: state.job }))
dom.wardrobeBtn.addEventListener('click', () => post('action', { action: 'wardrobe', job: state.job }))
dom.dutyBtn.addEventListener('click', () => post('action', { action: 'duty', job: state.job }))
document.getElementById('modalCancel').addEventListener('click', () => closeModal())
dom.modalConfirm.addEventListener('click', async () => {
  if (!modalState?.onConfirm) return
  await modalState.onConfirm()
  closeModal()
})
document.getElementById('modalBackdrop').addEventListener('click', () => closeModal())

document.addEventListener('keyup', e => {
  if (e.key === 'Escape') {
    if (dom.modal.classList.contains('open')) {
      closeModal()
    } else {
      post('close')
    }
  }
})

window.addEventListener('message', event => {
  const { action, data } = event.data || {}
  if (action === 'open') {
    showView('boss')
    showTab('overview')
    render(data)
  }
  if (action === 'openDuty') {
    showView('duty')
    renderDutyScreen(data)
  }
  if (action === 'refresh') {
    render(data)
  }
  if (action === 'close') {
    closeModal(false)
    app.classList.add('hidden')
    dom.shell.classList.add('hidden')
    dom.dutyShell.classList.add('hidden')
  }
})
