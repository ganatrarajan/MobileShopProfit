<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RepairHub — Admin Panel</title>
    <link rel="icon" type="image/x-icon" href="/favicon.ico">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #2563eb;
            --primary-hover: #1d4ed8;
            --bg-dark: #0f172a;
            --bg-card: #1e293b;
            --bg-body: #f8fafc;
            --text-main: #0f172a;
            --text-muted: #64748b;
            --border-color: #e2e8f0;
            --success: #16a34a;
            --warning: #d97706;
            --danger: #dc2626;
            --sidebar-width: 250px;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Inter', sans-serif;
        }

        body {
            background-color: var(--bg-body);
            color: var(--text-main);
            height: 100vh;
            display: flex;
            overflow: hidden;
        }

        /* --- AUTH LOGIN SCREEN --- */
        #auth-screen {
            position: fixed;
            inset: 0;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
        }

        .login-card {
            background: #ffffff;
            width: 100%;
            max-width: 420px;
            padding: 36px;
            border-radius: 16px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2), 0 10px 10px -5px rgba(0, 0, 0, 0.1);
        }

        .login-header {
            text-align: center;
            margin-bottom: 24px;
        }

        .login-header h2 {
            font-size: 22px;
            font-weight: 700;
            color: #0f172a;
        }

        .login-header p {
            font-size: 13px;
            color: #64748b;
            margin-top: 4px;
        }

        .form-group {
            margin-bottom: 18px;
        }

        .form-group label {
            display: block;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            color: #475569;
            margin-bottom: 6px;
        }

        .form-control {
            width: 100%;
            padding: 12px 14px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 14px;
            outline: none;
            transition: border 0.2s;
        }

        .form-control:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
        }

        .btn-primary {
            width: 100%;
            padding: 12px;
            background: var(--primary);
            color: white;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
            transition: background 0.2s;
        }

        .btn-primary:hover {
            background: var(--primary-hover);
        }

        .alert-error {
            background: #fef2f2;
            border: 1px solid #fecaca;
            color: #991b1b;
            padding: 10px 14px;
            border-radius: 8px;
            font-size: 13px;
            margin-bottom: 18px;
            display: none;
        }

        /* --- LAYOUT SIDEBAR & MAIN --- */
        #app-layout {
            display: flex;
            width: 100vw;
            height: 100vh;
            position: relative;
        }

        .sidebar {
            width: var(--sidebar-width);
            background: #0f172a;
            color: white;
            display: flex;
            flex-direction: column;
            z-index: 1050;
        }

        .sidebar-brand {
            padding: 20px;
            font-size: 18px;
            font-weight: 700;
            border-bottom: 1px solid #1e293b;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .sidebar-brand span {
            color: #38bdf8;
        }

        .sidebar-close-btn {
            display: none;
            background: none;
            border: none;
            color: #94a3b8;
            font-size: 20px;
            cursor: pointer;
        }

        .sidebar-menu {
            list-style: none;
            padding: 16px 10px;
            flex: 1;
            overflow-y: auto;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 14px;
            color: #94a3b8;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            border-radius: 8px;
            margin-bottom: 4px;
            transition: all 0.2s;
        }

        .nav-item:hover {
            background: #1e293b;
            color: white;
        }

        .nav-item.active {
            background: var(--primary);
            color: white;
        }

        .user-footer {
            padding: 16px 20px;
            border-top: 1px solid #1e293b;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 13px;
        }

        .main-content {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            background: #f8fafc;
        }

        .hamburger-btn {
            display: none;
            background: none;
            border: none;
            font-size: 22px;
            cursor: pointer;
            color: #0f172a;
            padding: 4px 8px;
            border-radius: 6px;
        }

        .hamburger-btn:hover {
            background: #f1f5f9;
        }

        .sidebar-overlay {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(3px);
            z-index: 1040;
        }

        .table-responsive {
            width: 100%;
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
        }

        .sub-nav-bar {
            display: flex;
            gap: 6px;
            margin-bottom: 20px;
            background: #ffffff;
            padding: 8px 12px;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
        }

        .sub-nav-btn {
            padding: 8px 16px;
            font-size: 13px;
            font-weight: 600;
            border-radius: 6px;
            border: none;
            background: transparent;
            color: #64748b;
            cursor: pointer;
            white-space: nowrap;
            transition: all 0.2s;
        }

        .sub-nav-btn:hover {
            background: #f1f5f9;
            color: #0f172a;
        }

        .sub-nav-btn.active {
            background: var(--primary);
            color: white;
        }

        @media (max-width: 768px) {
            .hamburger-btn {
                display: block;
            }

            .sidebar-close-btn {
                display: block;
            }

            .sidebar {
                position: fixed;
                top: 0;
                left: 0;
                bottom: 0;
                transform: translateX(-100%);
                transition: transform 0.3s ease;
                width: 260px;
                box-shadow: 4px 0 25px rgba(0,0,0,0.3);
            }

            .sidebar.mobile-open {
                transform: translateX(0);
            }

            .sidebar-overlay.mobile-open {
                display: block;
            }

            .topbar {
                padding: 0 16px;
            }

            .content-area {
                padding: 14px;
            }

            .grid-4 {
                grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
                gap: 10px;
            }

            .metric-card {
                padding: 14px;
            }

            .metric-value {
                font-size: 18px;
            }

            .modal-content {
                max-width: 94%;
                margin: 10px;
            }

            .table-toolbar {
                padding: 12px;
                gap: 8px;
                flex-direction: column;
                align-items: stretch;
            }

            .search-box {
                min-width: 100%;
            }
        }

        .topbar {
            height: 64px;
            background: white;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 28px;
        }

        .topbar h1 {
            font-size: 18px;
            font-weight: 700;
            color: #0f172a;
        }

        .content-area {
            flex: 1;
            padding: 24px 28px;
            overflow-y: auto;
        }

        /* --- CARDS & TABLES --- */
        .grid-4 {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 20px;
            margin-bottom: 24px;
        }

        .metric-card {
            background: white;
            padding: 20px;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }

        .metric-title {
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            color: #64748b;
        }

        .metric-value {
            font-size: 24px;
            font-weight: 700;
            color: #0f172a;
            margin: 8px 0 4px 0;
        }

        .metric-sub {
            font-size: 12px;
            color: #10b981;
            font-weight: 500;
        }

        .card-table {
            background: white;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
            overflow: hidden;
        }

        .table-toolbar {
            padding: 16px 20px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            background: #ffffff;
        }

        .search-box {
            position: relative;
            min-width: 260px;
        }

        .search-box input {
            width: 100%;
            padding: 9px 14px 9px 36px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 13px;
            outline: none;
            transition: all 0.2s;
        }

        .search-box input:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
        }

        .search-box::before {
            content: '🔍';
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 13px;
            opacity: 0.5;
        }

        .filter-select {
            padding: 9px 12px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 13px;
            outline: none;
            background: white;
            color: #334155;
            cursor: pointer;
        }

        .filter-select:focus {
            border-color: var(--primary);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
            font-size: 14px;
        }

        th {
            background: #f8fafc;
            padding: 12px 20px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            color: #475569;
            border-bottom: 1px solid var(--border-color);
        }

        td {
            padding: 14px 20px;
            border-bottom: 1px solid var(--border-color);
            color: #334155;
        }

        tr:last-child td {
            border-bottom: none;
        }

        tr:hover td {
            background: #f8fafc;
        }

        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
        }

        .badge-active { background: #dcfce7; color: #15803d; }
        .badge-inactive { background: #fee2e2; color: #b91c1c; }
        .badge-trial { background: #fef3c7; color: #b45309; }
        .badge-resolved { background: #e0e7ff; color: #4338ca; }

        .btn-sm {
            padding: 6px 12px;
            font-size: 12px;
            font-weight: 600;
            border-radius: 6px;
            border: 1px solid #cbd5e1;
            background: white;
            color: #334155;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-sm:hover {
            background: #f1f5f9;
        }

        .btn-danger-sm {
            background: #fef2f2;
            color: #991b1b;
            border-color: #fecaca;
        }

        .btn-danger-sm:hover {
            background: #fee2e2;
        }

        .btn-success-sm {
            background: #f0fdf4;
            color: #166534;
            border-color: #bbf7d0;
        }

        .btn-success-sm:hover {
            background: #dcfce7;
        }

        /* MODAL */
        #modal-container {
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(4px);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1100;
        }

        .modal-content {
            background: white;
            width: 100%;
            max-width: 540px;
            border-radius: 14px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
            overflow: hidden;
        }

        .modal-header {
            padding: 18px 24px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .modal-header h3 {
            font-size: 16px;
            font-weight: 700;
        }

        .modal-close {
            background: none;
            border: none;
            font-size: 20px;
            cursor: pointer;
            color: #64748b;
        }

        .modal-body {
            padding: 24px;
        }
    </style>
</head>
<body>

    <!-- LOGIN SCREEN -->
    <div id="auth-screen">
        <div class="login-card">
            <div class="login-header">
                <img src="/logo.png" alt="RepairHub Logo" style="height: 64px; width: 64px; margin: 0 auto 12px auto; display: block; border-radius: 14px; box-shadow: 0 4px 14px rgba(0,0,0,0.18);">
                <h2>RepairHub Admin</h2>
                <p>Platform Administrator Sign In</p>
            </div>
            <div id="login-alert" class="alert-error"></div>
            <form onsubmit="handleLogin(event)">
                <div class="form-group">
                    <label>Admin Mobile / Email</label>
                    <input type="text" id="login-input" class="form-control" placeholder="Enter admin mobile or email" required>
                </div>
                <div class="form-group">
                    <label>Password</label>
                    <input type="password" id="password-input" class="form-control" placeholder="Enter admin password" required>
                </div>
                <button type="submit" id="login-submit-btn" class="btn-primary">Sign In to Dashboard</button>
            </form>
        </div>
    </div>

    <!-- SIDEBAR BACKDROP OVERLAY FOR MOBILE -->
    <div id="sidebar-overlay" class="sidebar-overlay" onclick="toggleMobileSidebar()"></div>

    <!-- MAIN APP LAYOUT -->
    <div id="app-layout" style="display: none;">
        <aside class="sidebar">
            <div class="sidebar-brand">
                <div style="display:flex; align-items:center; gap:10px;">
                    <img src="/logo.png" alt="RepairHub Logo" style="width:34px; height:34px; border-radius:8px; object-fit:cover;">
                    <span style="font-weight:800; font-size:18px; letter-spacing:-0.5px; color:#ffffff;">Repair<span style="color:#60a5fa;">Hub</span></span>
                </div>
                <button class="sidebar-close-btn" onclick="toggleMobileSidebar()">✕</button>
            </div>
            <ul class="sidebar-menu">
                <li><a href="#dashboard" class="nav-item active" onclick="switchNav('dashboard')">📊 Dashboard</a></li>
                <li><a href="#shops" class="nav-item" onclick="switchNav('shops')">🏪 Shops Directory</a></li>
                <li><a href="#operations" class="nav-item" onclick="switchNav('operations')">📑 Shop Operations</a></li>
                <li><a href="#billing" class="nav-item" onclick="switchNav('billing')">💳 Subscriptions & Revenue</a></li>
                <li><a href="#reports" class="nav-item" onclick="switchNav('reports')">📈 Business Reports</a></li>
                <li><a href="#settings" class="nav-item" onclick="switchNav('settings')">⚙️ System & Settings</a></li>
            </ul>
            <div class="user-footer">
                <span id="admin-name">Admin</span>
                <a href="#" style="color:#ef4444; text-decoration:none; font-weight:600;" onclick="logout()">Logout</a>
            </div>
        </aside>

        <main class="main-content">
            <header class="topbar">
                <div style="display:flex; align-items:center; gap:12px;">
                    <button class="hamburger-btn" onclick="toggleMobileSidebar()">☰</button>
                    <h1 id="page-title">Dashboard Overview</h1>
                </div>
                <div>
                    <a href="/" target="_blank" style="font-size:12px; color:#2563eb; font-weight:600; text-decoration:none; background:#eff6ff; padding:6px 12px; border-radius:6px; display:inline-flex; align-items:center; gap:4px;">🌐 View Live Site</a>
                </div>
            </header>
            <div id="content-area" class="content-area">
                <!-- Dynamic Content View Loaded Here -->
            </div>
        </main>
    </div>

    <!-- GLOBAL MODAL -->
    <div id="modal-container">
        <div class="modal-content">
            <div class="modal-header">
                <h3 id="modal-title">Modal Title</h3>
                <button class="modal-close" onclick="closeModal()">✕</button>
            </div>
            <div id="modal-body" class="modal-body">
                <!-- Dynamic Modal Content -->
            </div>
        </div>
    </div>

    <script>
        const API_BASE = '/api/v1/admin';
        let authToken = localStorage.getItem('admin_token');

        document.addEventListener('DOMContentLoaded', () => {
            if (authToken) {
                checkAuth();
            } else {
                showAuthScreen();
            }
        });

        function showAuthScreen() {
            document.getElementById('auth-screen').style.display = 'flex';
            document.getElementById('app-layout').style.display = 'none';
        }

        function showAppLayout() {
            document.getElementById('auth-screen').style.display = 'none';
            document.getElementById('app-layout').style.display = 'flex';
            loadDashboardView();
        }

        async function checkAuth() {
            const data = await apiFetch('/auth/me');
            if (data && data.success) {
                document.getElementById('admin-name').innerText = data.data.user.name || 'Admin';
                showAppLayout();
            } else {
                logout();
            }
        }

        async function handleLogin(e) {
            e.preventDefault();
            const login = document.getElementById('login-input').value.trim();
            const password = document.getElementById('password-input').value;
            const alertBox = document.getElementById('login-alert');
            const submitBtn = document.getElementById('login-submit-btn');

            alertBox.style.display = 'none';
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerText = 'Authenticating...';
            }

            try {
                const res = await fetch('/api/v1/admin/auth/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                    body: JSON.stringify({ login, password })
                });
                const data = await res.json();

                if (res.ok && data.success && data.data && data.data.token) {
                    authToken = data.data.token;
                    localStorage.setItem('admin_token', authToken);
                    document.getElementById('admin-name').innerText = data.data.user.name || 'Admin';
                    showAppLayout();
                } else {
                    let errMsg = data.message || 'Invalid credentials or non-admin account';
                    if (data.errors) {
                        errMsg = Object.values(data.errors).flat().join(' ');
                    }
                    alertBox.innerText = errMsg;
                    alertBox.style.display = 'block';
                }
            } catch (err) {
                alertBox.innerText = 'Server connection error. Please try again.';
                alertBox.style.display = 'block';
            } finally {
                if (submitBtn) {
                    submitBtn.disabled = false;
                    submitBtn.innerText = 'Sign In to Dashboard';
                }
            }
        }

        function logout() {
            if (authToken) {
                apiFetch('/auth/logout', 'POST');
            }
            localStorage.removeItem('admin_token');
            authToken = null;
            showAuthScreen();
        }

        // Mobile Sidebar Toggles & Responsive Content Helper
        function toggleMobileSidebar() {
            document.querySelector('.sidebar').classList.toggle('mobile-open');
            document.getElementById('sidebar-overlay').classList.toggle('mobile-open');
        }

        function closeMobileSidebar() {
            document.querySelector('.sidebar').classList.remove('mobile-open');
            document.getElementById('sidebar-overlay').classList.remove('mobile-open');
        }

        function getContentContainer() {
            return document.getElementById('sub-content-area') || document.getElementById('content-area');
        }

        // Navigation Switcher & Section Sub-Tabs Router
        function switchNav(route, subTab = '') {
            closeMobileSidebar();

            // Map individual sub-routes to 6 main sidebar sections
            let mainSection = route;
            if (['sales', 'repairs', 'customers', 'inventory', 'expenses', 'warranties', 'technicians', 'operations'].includes(route)) {
                mainSection = 'operations';
                subTab = subTab || (route === 'operations' ? 'sales' : route);
            } else if (['subscriptions', 'payments', 'plans', 'revenue', 'billing'].includes(route)) {
                mainSection = 'billing';
                subTab = subTab || (route === 'billing' ? 'subscriptions' : route);
            } else if (['pages', 'gateway', 'support', 'audit', 'users', 'settings'].includes(route)) {
                mainSection = 'settings';
                subTab = subTab || (route === 'settings' ? 'pages' : route);
            }

            document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
            const activeNav = document.querySelector(`.nav-item[href="#${mainSection}"]`);
            if (activeNav) activeNav.classList.add('active');

            const titleMap = {
                'dashboard': 'Dashboard Overview',
                'shops': 'Shops Directory',
                'operations': 'Shop Operations Data Hub',
                'billing': 'Subscriptions & Revenue Billing',
                'reports': 'Platform Business & Financial Reports',
                'settings': 'System & Platform Settings'
            };
            document.getElementById('page-title').innerText = titleMap[mainSection] || 'Admin Panel';

            if (mainSection === 'dashboard') {
                loadDashboardView();
            } else if (mainSection === 'shops') {
                loadShopsView();
            } else if (mainSection === 'reports') {
                loadReportsView();
            } else if (mainSection === 'operations') {
                renderSubNavBar('operations', subTab, [
                    { id: 'sales', label: '🛒 Sales & Invoices', fn: loadSalesView },
                    { id: 'repairs', label: '🔧 Repair Jobs', fn: loadRepairsView },
                    { id: 'customers', label: '👥 Customer Directory', fn: loadCustomersView },
                    { id: 'inventory', label: '📦 Inventory Stock', fn: loadInventoryView },
                    { id: 'expenses', label: '💸 Shop Expenses', fn: loadExpensesView },
                    { id: 'warranties', label: '🛡️ Warranties', fn: loadWarrantiesView },
                    { id: 'technicians', label: '🧰 Technicians', fn: loadTechniciansView },
                ]);
            } else if (mainSection === 'billing') {
                renderSubNavBar('billing', subTab, [
                    { id: 'subscriptions', label: '💳 Subscriptions', fn: loadSubscriptionsView },
                    { id: 'payments', label: '🧾 Real Payments', fn: loadPaymentsView },
                    { id: 'plans', label: '🏷️ Plans & Pricing', fn: loadPlansView },
                    { id: 'revenue', label: '📈 Revenue Analytics', fn: loadRevenueView },
                ]);
            } else if (mainSection === 'settings') {
                renderSubNavBar('settings', subTab, [
                    { id: 'pages', label: '📄 Legal Pages CMS', fn: loadPagesView },
                    { id: 'gateway', label: '⚙️ Gateway Settings', fn: loadGatewayView },
                    { id: 'support', label: '💬 Support Tickets', fn: loadSupportView },
                    { id: 'audit', label: '🛡️ Audit Logs', fn: loadAuditView },
                    { id: 'users', label: '👥 User Accounts', fn: loadUsersView },
                ]);
            }
        }

        function renderSubNavBar(section, activeSub, tabs) {
            const contentArea = document.getElementById('content-area');
            const navHtml = `
                <div class="sub-nav-bar">
                    ${tabs.map(t => `
                        <button class="sub-nav-btn ${t.id === activeSub ? 'active' : ''}" onclick="switchNav('${section}', '${t.id}')">
                            ${t.label}
                        </button>
                    `).join('')}
                </div>
                <div id="sub-content-area"></div>
            `;
            contentArea.innerHTML = navHtml;

            const targetTab = tabs.find(t => t.id === activeSub) || tabs[0];
            if (targetTab && typeof targetTab.fn === 'function') {
                targetTab.fn();
            }
        }

        // Helper API Fetcher
        async function apiFetch(endpoint, method = 'GET', body = null) {
            const opts = {
                method,
                headers: { 'Authorization': `Bearer ${authToken}`, 'Accept': 'application/json', 'Content-Type': 'application/json' }
            };
            if (body) opts.body = JSON.stringify(body);
            const res = await fetch(`${API_BASE}${endpoint}`, opts);
            return await res.json();
        }

        let _searchDebounceTimer = null;
        function debounceSearch(fn) {
            if (_searchDebounceTimer) clearTimeout(_searchDebounceTimer);
            _searchDebounceTimer = setTimeout(fn, 350);
        }

        function renderPagination(meta, fnName, ...extraArgs) {
            if (!meta || meta.last_page <= 1) return '';
            const current = meta.current_page;
            const last = meta.last_page;
            const total = meta.total || 0;
            const from = meta.from || (((current - 1) * meta.per_page) + 1);
            const to = meta.to || Math.min(current * meta.per_page, total);
            const extraStr = extraArgs.map(a => typeof a === 'string' ? `'${a.replace(/'/g, "\'")}'` : a).join(', ');
            const comma = extraStr ? ', ' : '';

            return `
                <div style="display:flex; align-items:center; justify-content:space-between; padding:14px 20px; border-top:1px solid #e2e8f0; font-size:13px; color:#64748b; background:#f8fafc;">
                    <div>Showing <strong>${from}-${to}</strong> of <strong>${total}</strong> records</div>
                    <div style="display:flex; gap:8px; align-items:center;">
                        <button class="btn-sm" ${current <= 1 ? 'disabled style="opacity:0.4; cursor:not-allowed;"' : ''} onclick="${fnName}(${current - 1}${comma}${extraStr})">← Prev</button>
                        <span style="font-weight:600; color:#1e293b; padding:0 6px;">Page ${current} of ${last}</span>
                        <button class="btn-sm" ${current >= last ? 'disabled style="opacity:0.4; cursor:not-allowed;"' : ''} onclick="${fnName}(${current + 1}${comma}${extraStr})">Next →</button>
                    </div>
                </div>
            `;
        }

        // 1. DASHBOARD VIEW
        async function loadDashboardView() {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading overview metrics...</div>';
            const data = await apiFetch('/dashboard');

            if (!data.success) return;
            const m = data.data;

            content.innerHTML = `
                <div class="grid-4">
                    <div class="metric-card">
                        <div class="metric-title">Total Shops</div>
                        <div class="metric-value">${m.shops.total}</div>
                        <div class="metric-sub">${m.shops.active} Active | ${m.shops.new_month} New This Month</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Subscriptions</div>
                        <div class="metric-value">${m.subscriptions.active}</div>
                        <div class="metric-sub">${m.subscriptions.trial} Trial | ${m.subscriptions.expired} Expired</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Total Platform Revenue</div>
                        <div class="metric-value">₹${m.business.total_revenue.toLocaleString()}</div>
                        <div class="metric-sub">₹${m.business.revenue_this_month.toLocaleString()} This Month</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Platform Repairs & Sales</div>
                        <div class="metric-value">${m.usage.total_repairs} Repairs</div>
                        <div class="metric-sub">${m.usage.total_sales} Total Sales Recorded</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="font-weight:700; font-size:15px;">Recently Registered Shops</div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Owner</th>
                                <th>Mobile</th>
                                <th>Registered</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${m.recent_shops.map(s => `
                                <tr>
                                    <td><strong>${s.name}</strong></td>
                                    <td>${s.owner_name}</td>
                                    <td>${s.phone || s.mobile || (s.user ? (s.user.mobile || s.user.phone) : 'N/A')}</td>
                                    <td>${new Date(s.created_at).toLocaleDateString()}</td>
                                    <td><span class="badge ${s.status === 'active' ? 'badge-active' : 'badge-inactive'}">${s.status}</span></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                </div>
            `;
        }

        // 2. SHOPS VIEW
        async function loadShopsView(page = 1, search = '', status = '', subStatus = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/shops?page=${page}&search=${encodeURIComponent(search)}&status=${status}&subscription_status=${subStatus}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const shops = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="shops-search-input" placeholder="Search shop name, owner, phone, email..." value="${search}" oninput="debounceSearch(() => loadShopsView(1, document.getElementById('shops-search-input').value, '${status}', '${subStatus}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadShopsView(1, '${search}', this.value, '${subStatus}')">
                                <option value="">Account: All Statuses</option>
                                <option value="active" ${status === 'active' ? 'selected' : ''}>Active Account</option>
                                <option value="deactivated" ${status === 'deactivated' ? 'selected' : ''}>Deactivated Account</option>
                            </select>
                            <select class="filter-select" onchange="loadShopsView(1, '${search}', '${status}', this.value)">
                                <option value="">Plan: All Subscriptions</option>
                                <option value="active" ${subStatus === 'active' ? 'selected' : ''}>Active Plan</option>
                                <option value="trial" ${subStatus === 'trial' ? 'selected' : ''}>Trial</option>
                                <option value="expired" ${subStatus === 'expired' ? 'selected' : ''}>Expired</option>
                            </select>
                            ${(search || status || subStatus) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadShopsView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Owner Name</th>
                                <th>Contact Number</th>
                                <th>Registration Date</th>
                                <th>Subscription</th>
                                <th>Account Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${shops.length === 0 ? `<tr><td colspan="7" style="text-align:center; padding:30px; color:#94a3b8;">No shops found matching filter criteria.</td></tr>` : ''}
                            ${shops.map(s => {
                                const mob = s.phone || s.mobile || (s.user ? (s.user.mobile || s.user.phone) : 'N/A');
                                const sub = s.latest_subscription ? s.latest_subscription.status : 'trial';
                                return `
                                <tr>
                                    <td><strong>${s.name}</strong></td>
                                    <td>${s.owner_name}</td>
                                    <td>${mob}</td>
                                    <td>${new Date(s.created_at).toLocaleDateString()}</td>
                                    <td><span class="badge ${sub === 'active' ? 'badge-active' : (sub === 'expired' ? 'badge-inactive' : 'badge-trial')}">${sub.toUpperCase()}</span></td>
                                    <td><span class="badge ${s.status === 'active' ? 'badge-active' : 'badge-inactive'}">${s.status}</span></td>
                                    <td>
                                        <button class="btn-sm" onclick="openShopDetails(${s.id})">Details</button>
                                        <button class="btn-sm ${s.status === 'active' ? 'btn-danger-sm' : 'btn-success-sm'}" onclick="toggleShopStatus(${s.id}, '${s.status === 'active' ? 'deactivated' : 'active'}')">
                                            ${s.status === 'active' ? 'Deactivate' : 'Activate'}
                                        </button>
                                    </td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadShopsView', search, status, subStatus)}
                </div>
            `;
        }

        let _cachedShopsList = null;
        async function getShopsDropdownOptions(selectedId = '') {
            if (!_cachedShopsList) {
                const res = await apiFetch('/shops?per_page=100');
                if (res && res.success && res.data) {
                    _cachedShopsList = res.data.data || [];
                } else {
                    _cachedShopsList = [];
                }
            }
            let html = '<option value="">All Shops</option>';
            _cachedShopsList.forEach(s => {
                const sel = String(s.id) === String(selectedId) ? 'selected' : '';
                html += `<option value="${s.id}" ${sel}>${s.name}</option>`;
            });
            return html;
        }

        async function openShopDetails(id) {
            const data = await apiFetch(`/shops/${id}`);
            if (!data.success) return;
            const s = data.data;

            const mob = s.contact_mobile || s.phone || s.mobile || (s.user ? (s.user.mobile || s.user.phone) : 'N/A');
            const email = s.contact_email || s.email || (s.user ? s.user.email : 'N/A');

            openModal(`Shop Details — ${s.name}`, `
                <div style="font-size:13px; line-height:1.5;">
                    <div style="display:flex; gap:8px; border-bottom:1px solid #e2e8f0; margin-bottom:14px; padding-bottom:8px; overflow-x:auto;">
                        <button class="btn-sm" style="background:#2563eb; color:white; border:none;" onclick="switchShopTab('overview')">📋 Overview</button>
                        <button class="btn-sm" onclick="switchShopTab('sales')">🛒 Sales (${s.sales_count})</button>
                        <button class="btn-sm" onclick="switchShopTab('repairs')">🔧 Repairs (${s.repairs_count})</button>
                        <button class="btn-sm" onclick="switchShopTab('customers')">👥 Customers (${s.customers_count})</button>
                        <button class="btn-sm" onclick="switchShopTab('inventory')">📦 Stock (${s.inventory_items_count})</button>
                    </div>

                    <div id="shop-tab-overview">
                        <p><strong>Shop Name:</strong> ${s.name}</p>
                        <p><strong>Owner:</strong> ${s.owner_name}</p>
                        <p><strong>Contact Mobile:</strong> ${mob} | <strong>Email:</strong> ${email}</p>
                        <p><strong>Registration Date:</strong> ${new Date(s.created_at).toLocaleString()}</p>
                        <p><strong>Account Status:</strong> <span class="badge ${s.status === 'active' ? 'badge-active' : 'badge-inactive'}">${s.status}</span></p>
                        <hr style="margin:12px 0; border:0; border-top:1px solid #e2e8f0;">
                        <h4 style="font-size:12px; text-transform:uppercase; color:#64748b; margin-bottom:8px;">Platform Usage Totals</h4>
                        <div style="display:grid; grid-template-columns:1fr 1fr; gap:8px;">
                            <div style="background:#f8fafc; padding:8px; border-radius:6px;"><strong>Customers Logged:</strong> ${s.customers_count}</div>
                            <div style="background:#f8fafc; padding:8px; border-radius:6px;"><strong>Repairs Logged:</strong> ${s.repairs_count}</div>
                            <div style="background:#f8fafc; padding:8px; border-radius:6px;"><strong>Sales Invoices:</strong> ${s.sales_count}</div>
                            <div style="background:#f8fafc; padding:8px; border-radius:6px;"><strong>Devices Logged:</strong> ${s.devices_count}</div>
                            <div style="background:#f8fafc; padding:8px; border-radius:6px; grid-column:span 2;"><strong>Stock Items:</strong> ${s.inventory_items_count}</div>
                        </div>
                    </div>

                    <div id="shop-tab-sales" style="display:none;">
                        <h4 style="font-size:13px; font-weight:700; margin-bottom:8px;">Recent Sales Invoices</h4>
                        ${(s.recent_sales || []).length === 0 ? '<p style="color:#94a3b8;">No sales logged yet for this shop.</p>' : `
                            <table style="width:100%; border-collapse:collapse; font-size:12px;">
                                <thead>
                                    <tr style="background:#f8fafc;"><th>Invoice #</th><th>Customer</th><th>Date</th><th>Total</th><th>Status</th></tr>
                                </thead>
                                <tbody>
                                    ${s.recent_sales.map(rs => `
                                        <tr>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${rs.invoice_number || 'INV-' + rs.id}</td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${rs.customer_name}</td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${new Date(rs.sale_date || rs.created_at).toLocaleDateString()}</td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">₹${parseFloat(rs.grand_total).toFixed(2)}</td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;"><span class="badge ${rs.payment_status === 'paid' ? 'badge-active' : 'badge-trial'}">${rs.payment_status}</span></td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        `}
                    </div>

                    <div id="shop-tab-repairs" style="display:none;">
                        <h4 style="font-size:13px; font-weight:700; margin-bottom:8px;">Recent Repair Jobs</h4>
                        ${(s.recent_repairs || []).length === 0 ? '<p style="color:#94a3b8;">No repair jobs logged yet for this shop.</p>' : `
                            <table style="width:100%; border-collapse:collapse; font-size:12px;">
                                <thead>
                                    <tr style="background:#f8fafc;"><th>Job #</th><th>Problem</th><th>Cost</th><th>Status</th></tr>
                                </thead>
                                <tbody>
                                    ${s.recent_repairs.map(rr => `
                                        <tr>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${rr.job_number || 'JOB-' + rr.id}</td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${rr.problem_description || 'N/A'}</td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">₹${parseFloat(rr.final_cost > 0 ? rr.final_cost : rr.estimated_cost).toFixed(2)}</td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;"><span class="badge badge-trial">${rr.repair_status}</span></td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        `}
                    </div>

                    <div id="shop-tab-customers" style="display:none;">
                        <h4 style="font-size:13px; font-weight:700; margin-bottom:8px;">Recent Customers</h4>
                        ${(s.recent_customers || []).length === 0 ? '<p style="color:#94a3b8;">No customers registered for this shop.</p>' : `
                            <ul style="list-style:none; padding:0;">
                                ${s.recent_customers.map(rc => `
                                    <li style="padding:6px; border-bottom:1px solid #e2e8f0; display:flex; justify-content:space-between;">
                                        <span><strong>${rc.name}</strong> (${rc.mobile})</span>
                                        <span style="color:#64748b; font-size:11px;">Added ${new Date(rc.created_at).toLocaleDateString()}</span>
                                    </li>
                                `).join('')}
                            </ul>
                        `}
                    </div>

                    <div id="shop-tab-inventory" style="display:none;">
                        <h4 style="font-size:13px; font-weight:700; margin-bottom:8px;">Recent Stock Items</h4>
                        ${(s.recent_inventory || []).length === 0 ? '<p style="color:#94a3b8;">No inventory items for this shop.</p>' : `
                            <table style="width:100%; border-collapse:collapse; font-size:12px;">
                                <thead>
                                    <tr style="background:#f8fafc;"><th>Item Name</th><th>SKU</th><th>Stock</th><th>Price</th></tr>
                                </thead>
                                <tbody>
                                    ${s.recent_inventory.map(ri => `
                                        <tr>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${ri.name}</td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${ri.sku || '—'}</td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;"><strong>${ri.current_stock}</strong></td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">₹${parseFloat(ri.selling_price).toFixed(2)}</td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        `}
                    </div>
                </div>
            `);
        }

        function switchShopTab(tab) {
            ['overview', 'sales', 'repairs', 'customers', 'inventory'].forEach(t => {
                const el = document.getElementById(`shop-tab-${t}`);
                if (el) el.style.display = t === tab ? 'block' : 'none';
            });
        }

        async function toggleShopStatus(id, newStatus) {
            if (!confirm(`Are you sure you want to change this shop status to ${newStatus}?`)) return;
            const data = await apiFetch(`/shops/${id}/toggle-status`, 'POST', { status: newStatus, reason: 'Admin panel toggle' });
            if (data.success) {
                alert(`Shop has been ${newStatus}.`);
                loadShopsView();
            }
        }

        // 3. USERS VIEW
        async function loadUsersView(page = 1, search = '', role = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/users?page=${page}&search=${encodeURIComponent(search)}&role=${role}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const users = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="users-search-input" placeholder="Search user name, mobile, email..." value="${search}" oninput="debounceSearch(() => loadUsersView(1, document.getElementById('users-search-input').value, '${role}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadUsersView(1, '${search}', this.value)">
                                <option value="">All Roles</option>
                                <option value="owner" ${role === 'owner' ? 'selected' : ''}>Shop Owner</option>
                                <option value="admin" ${role === 'admin' ? 'selected' : ''}>SaaS Admin</option>
                            </select>
                            ${(search || role) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadUsersView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Mobile / Email</th>
                                <th>Associated Shop</th>
                                <th>User Role</th>
                                <th>Created Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${users.length === 0 ? `<tr><td colspan="5" style="text-align:center; padding:30px; color:#94a3b8;">No users found matching filter criteria.</td></tr>` : ''}
                            ${users.map(u => `
                                <tr>
                                    <td><strong>${u.name}</strong></td>
                                    <td>${u.mobile} ${u.email ? `(${u.email})` : ''}</td>
                                    <td>${u.shop ? u.shop.name : 'N/A (Admin)'}</td>
                                    <td><span class="badge badge-resolved">${u.role}</span></td>
                                    <td>${new Date(u.created_at).toLocaleDateString()}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadUsersView', search, role)}
                </div>
            `;
        }

        // 4. SUBSCRIPTIONS VIEW
        async function loadSubscriptionsView(page = 1, search = '', status = '', paymentStatus = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/subscriptions?page=${page}&search=${encodeURIComponent(search)}&status=${status}&payment_status=${paymentStatus}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const subs = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="subs-search-input" placeholder="Search by shop name, owner..." value="${search}" oninput="debounceSearch(() => loadSubscriptionsView(1, document.getElementById('subs-search-input').value, '${status}', '${paymentStatus}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadSubscriptionsView(1, '${search}', this.value, '${paymentStatus}')">
                                <option value="">Status: All</option>
                                <option value="trial" ${status === 'trial' ? 'selected' : ''}>Trial</option>
                                <option value="active" ${status === 'active' ? 'selected' : ''}>Active</option>
                                <option value="expired" ${status === 'expired' ? 'selected' : ''}>Expired</option>
                                <option value="cancelled" ${status === 'cancelled' ? 'selected' : ''}>Cancelled</option>
                            </select>
                            <select class="filter-select" onchange="loadSubscriptionsView(1, '${search}', '${status}', this.value)">
                                <option value="">Payment: All</option>
                                <option value="paid" ${paymentStatus === 'paid' ? 'selected' : ''}>Paid</option>
                                <option value="pending" ${paymentStatus === 'pending' ? 'selected' : ''}>Pending</option>
                                <option value="free" ${paymentStatus === 'free' ? 'selected' : ''}>Free</option>
                            </select>
                            ${(search || status || paymentStatus) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadSubscriptionsView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Current Plan</th>
                                <th>Subscription Status</th>
                                <th>Payment Status</th>
                                <th>Expiry Date</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${subs.length === 0 ? `<tr><td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No subscriptions found matching filter criteria.</td></tr>` : ''}
                            ${subs.map(s => `
                                <tr>
                                    <td><strong>${s.shop ? s.shop.name : 'Shop #' + s.shop_id}</strong></td>
                                    <td>${s.plan ? s.plan.name : 'Default Plan'}</td>
                                    <td><span class="badge ${s.status === 'active' ? 'badge-active' : (s.status === 'expired' ? 'badge-inactive' : 'badge-trial')}">${s.status.toUpperCase()}</span></td>
                                    <td><span class="badge ${s.payment_status === 'paid' ? 'badge-active' : 'badge-trial'}">${s.payment_status}</span></td>
                                    <td>${s.expiry_date ? new Date(s.expiry_date).toLocaleDateString() : 'N/A'}</td>
                                    <td>
                                        <button class="btn-sm" onclick="editSubscription(${s.id}, ${s.plan_id || 1}, '${s.status}', '${s.expiry_date ? s.expiry_date.substring(0, 10) : ''}', '${s.payment_status}')">Manage</button>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadSubscriptionsView', search, status, paymentStatus)}
                </div>
            `;
        }

        async function editSubscription(id, currentPlanId, currentStatus, currentExpiry, currentPaymentStatus) {
            openModal('Manage Subscription', `
                <form onsubmit="saveSubscriptionUpdate(event, ${id})">
                    <div class="form-group">
                        <label>Subscription Status</label>
                        <select id="sub-edit-status" class="form-control">
                            <option value="trial" ${currentStatus === 'trial' ? 'selected' : ''}>Trial</option>
                            <option value="active" ${currentStatus === 'active' ? 'selected' : ''}>Active</option>
                            <option value="expired" ${currentStatus === 'expired' ? 'selected' : ''}>Expired</option>
                            <option value="cancelled" ${currentStatus === 'cancelled' ? 'selected' : ''}>Cancelled</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Payment Status</label>
                        <select id="sub-edit-payment" class="form-control">
                            <option value="paid" ${currentPaymentStatus === 'paid' ? 'selected' : ''}>Paid</option>
                            <option value="pending" ${currentPaymentStatus === 'pending' ? 'selected' : ''}>Pending</option>
                            <option value="free" ${currentPaymentStatus === 'free' ? 'selected' : ''}>Free</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Expiry Date</label>
                        <input type="date" id="sub-edit-expiry" class="form-control" value="${currentExpiry}">
                    </div>
                    <div style="margin-top:20px; display:flex; gap:10px;">
                        <button type="submit" class="btn-primary" style="flex:1;">Update Subscription</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        async function saveSubscriptionUpdate(e, id) {
            e.preventDefault();
            const body = {
                status: document.getElementById('sub-edit-status').value,
                payment_status: document.getElementById('sub-edit-payment').value,
                expiry_date: document.getElementById('sub-edit-expiry').value,
            };
            const data = await apiFetch(`/subscriptions/${id}/status`, 'PUT', body);
            if (data && data.success) {
                alert('Subscription updated successfully!');
                closeModal();
                loadSubscriptionsView();
            } else {
                alert(data.message || 'Failed to update subscription');
            }
        }

        // 5. PAYMENTS VIEW
        async function loadPaymentsView(page = 1, search = '', status = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/payments?page=${page}&search=${encodeURIComponent(search)}&status=${status}`);
            if (!data || data.status !== 'success') return;
            const pageData = data.data;
            const payments = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="payments-search-input" placeholder="Search order ID, payment ID, shop..." value="${search}" oninput="debounceSearch(() => loadPaymentsView(1, document.getElementById('payments-search-input').value, '${status}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadPaymentsView(1, '${search}', this.value)">
                                <option value="">Status: All</option>
                                <option value="successful" ${status === 'successful' ? 'selected' : ''}>Successful</option>
                                <option value="pending" ${status === 'pending' ? 'selected' : ''}>Pending</option>
                                <option value="failed" ${status === 'failed' ? 'selected' : ''}>Failed</option>
                            </select>
                            ${(search || status) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadPaymentsView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Order ID</th>
                                <th>Payment ID</th>
                                <th>Amount</th>
                                <th>Method</th>
                                <th>Status</th>
                                <th>Timestamp</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${payments.length === 0 ? `<tr><td colspan="7" style="text-align:center; padding:30px; color:#94a3b8;">No payment records found matching filter criteria.</td></tr>` : ''}
                            ${payments.map(p => `
                                <tr>
                                    <td><strong>${p.shop ? p.shop.name : 'Shop #' + p.shop_id}</strong></td>
                                    <td><span style="font-family:monospace; font-size:12px;">${p.order_id}</span></td>
                                    <td><span style="font-family:monospace; font-size:12px;">${p.payment_id || '—'}</span></td>
                                    <td><strong>₹${parseFloat(p.amount).toFixed(2)}</strong></td>
                                    <td>${p.payment_method || 'Razorpay'}</td>
                                    <td><span class="badge ${p.status === 'successful' ? 'badge-active' : (p.status === 'failed' ? 'badge-inactive' : 'badge-trial')}">${p.status.toUpperCase()}</span></td>
                                    <td>${new Date(p.created_at).toLocaleString()}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadPaymentsView', search, status)}
                </div>
            `;
        }

        // 6. PLANS VIEW
        async function loadPlansView(search = '', status = '') {
            const content = getContentContainer();
            const data = await apiFetch('/plans');
            if (!data || !data.success) return;
            let plans = data.data || [];

            if (search) {
                const sLower = search.toLowerCase();
                plans = plans.filter(p => p.name.toLowerCase().includes(sLower) || p.billing_period.toLowerCase().includes(sLower));
            }
            if (status) {
                plans = plans.filter(p => p.status === status);
            }

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="plans-search-input" placeholder="Search plan name, billing period..." value="${search}" oninput="debounceSearch(() => loadPlansView(document.getElementById('plans-search-input').value, '${status}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadPlansView('${search}', this.value)">
                                <option value="">Status: All</option>
                                <option value="active" ${status === 'active' ? 'selected' : ''}>Active</option>
                                <option value="inactive" ${status === 'inactive' ? 'selected' : ''}>Inactive</option>
                            </select>
                            ${(search || status) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadPlansView('', '')">Clear Filters</button>` : ''}
                            <button class="btn-primary" style="padding:8px 16px; width:auto; font-size:13px;" onclick="createPlanModal()">+ Create New Plan</button>
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Plan Name</th>
                                <th>Price</th>
                                <th>Billing Cycle</th>
                                <th>Sort Order</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${plans.length === 0 ? `<tr><td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No plans found matching filter criteria.</td></tr>` : ''}
                            ${plans.map(p => `
                                <tr>
                                    <td><strong>${p.name}</strong></td>
                                    <td><strong>₹${parseFloat(p.price).toFixed(2)}</strong></td>
                                    <td>${p.billing_period}</td>
                                    <td>${p.sort_order || 0}</td>
                                    <td><span class="badge ${p.status === 'active' ? 'badge-active' : 'badge-inactive'}">${p.status}</span></td>
                                    <td>
                                        <button class="btn-sm" onclick="editPlanModal(${p.id}, '${p.name.replace(/'/g, "\'")}', ${p.price}, '${p.billing_period}', ${p.sort_order || 0}, '${p.status}')">Edit</button>
                                        <button class="btn-sm ${p.status === 'active' ? 'btn-danger-sm' : 'btn-success-sm'}" onclick="togglePlanStatus(${p.id})">
                                            ${p.status === 'active' ? 'Disable' : 'Enable'}
                                        </button>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                </div>
            `;
        }

        function createPlanModal() {
            openModal('Create New Plan', `
                <form onsubmit="saveNewPlan(event)">
                    <div class="form-group">
                        <label>Plan Name</label>
                        <input type="text" id="new-plan-name" class="form-control" placeholder="e.g. Annual Pro Plan" required>
                    </div>
                    <div class="form-group">
                        <label>Price (INR)</label>
                        <input type="number" step="0.01" id="new-plan-price" class="form-control" placeholder="99.00" required>
                    </div>
                    <div class="form-group">
                        <label>Billing Period</label>
                        <select id="new-plan-period" class="form-control">
                            <option value="monthly">Monthly</option>
                            <option value="3_months">3 Months</option>
                            <option value="6_months">6 Months</option>
                            <option value="annual">Annual (12 Months)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Sort Order</label>
                        <input type="number" id="new-plan-sort" class="form-control" value="1">
                    </div>
                    <div style="margin-top:20px; display:flex; gap:10px;">
                        <button type="submit" class="btn-primary" style="flex:1;">Create Plan</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        async function saveNewPlan(e) {
            e.preventDefault();
            const body = {
                name: document.getElementById('new-plan-name').value,
                price: parseFloat(document.getElementById('new-plan-price').value),
                billing_period: document.getElementById('new-plan-period').value,
                sort_order: parseInt(document.getElementById('new-plan-sort').value),
                status: 'active',
            };
            const res = await apiFetch('/plans', 'POST', body);
            if (res && res.success) {
                alert('Plan created successfully!');
                closeModal();
                loadPlansView();
            } else {
                alert(res.message || 'Failed to create plan');
            }
        }

        function editPlanModal(id, name, price, period, sort, status) {
            openModal('Edit Subscription Plan', `
                <form onsubmit="savePlanUpdate(event, ${id})">
                    <div class="form-group">
                        <label>Plan Name</label>
                        <input type="text" id="edit-plan-name" class="form-control" value="${name}" required>
                    </div>
                    <div class="form-group">
                        <label>Price (INR)</label>
                        <input type="number" step="0.01" id="edit-plan-price" class="form-control" value="${price}" required>
                    </div>
                    <div class="form-group">
                        <label>Billing Period</label>
                        <select id="edit-plan-period" class="form-control">
                            <option value="monthly" ${period === 'monthly' ? 'selected' : ''}>Monthly</option>
                            <option value="3_months" ${period === '3_months' ? 'selected' : ''}>3 Months</option>
                            <option value="6_months" ${period === '6_months' ? 'selected' : ''}>6 Months</option>
                            <option value="annual" ${period === 'annual' ? 'selected' : ''}>Annual (12 Months)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Sort Order</label>
                        <input type="number" id="edit-plan-sort" class="form-control" value="${sort}">
                    </div>
                    <div class="form-group">
                        <label>Status</label>
                        <select id="edit-plan-status" class="form-control">
                            <option value="active" ${status === 'active' ? 'selected' : ''}>Active</option>
                            <option value="inactive" ${status === 'inactive' ? 'selected' : ''}>Inactive</option>
                        </select>
                    </div>
                    <div style="margin-top:20px; display:flex; gap:10px;">
                        <button type="submit" class="btn-primary" style="flex:1;">Update Plan</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        async function savePlanUpdate(e, id) {
            e.preventDefault();
            const body = {
                name: document.getElementById('edit-plan-name').value,
                price: parseFloat(document.getElementById('edit-plan-price').value),
                billing_period: document.getElementById('edit-plan-period').value,
                sort_order: parseInt(document.getElementById('edit-plan-sort').value),
                status: document.getElementById('edit-plan-status').value,
            };
            const res = await apiFetch(`/plans/${id}`, 'PUT', body);
            if (res && res.success) {
                alert('Plan updated successfully!');
                closeModal();
                loadPlansView();
            } else {
                alert(res.message || 'Failed to update plan');
            }
        }

        async function togglePlanStatus(id) {
            const res = await apiFetch(`/plans/${id}/toggle-status`, 'POST');
            if (res && res.success) {
                loadPlansView();
            } else {
                alert(res.message || 'Failed to toggle status');
            }
        }

        // 7. REVENUE VIEW
        async function loadRevenueView() {
            const content = getContentContainer();
            const data = await apiFetch('/revenue');
            if (!data || !data.success) return;
            const r = data.data;

            content.innerHTML = `
                <div class="grid-4">
                    <div class="metric-card">
                        <div class="metric-title">Total Platform Revenue</div>
                        <div class="metric-value">₹${r.total_revenue.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Revenue This Month</div>
                        <div class="metric-value">₹${r.revenue_this_month.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Paid Subscriptions</div>
                        <div class="metric-value">${r.paid_subscriptions_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Failed Payments</div>
                        <div class="metric-value">${r.failed_payments_count || 0}</div>
                    </div>
                </div>
            `;
        }

        // 8. PAYMENT GATEWAY SETTINGS VIEW
        async function loadGatewayView() {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading gateway configuration...</div>';
            const res = await apiFetch('/settings/payment-gateway');
            if (!res || res.status !== 'success') return;
            const g = res.data;

            content.innerHTML = `
                <div class="card-table" style="padding:24px; max-width:650px;">
                    <h3 style="font-size:18px; font-weight:700; margin-bottom:16px;">Razorpay Gateway Settings</h3>
                    <div id="gw-alert" class="alert-error"></div>
                    <form onsubmit="saveGatewaySettings(event)">
                        <div class="form-group">
                            <label>Gateway Status</label>
                            <select id="gw-active" class="form-control">
                                <option value="1" ${g.active ? 'selected' : ''}>Enabled</option>
                                <option value="0" ${!g.active ? 'selected' : ''}>Disabled</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Environment Mode</label>
                            <select id="gw-mode" class="form-control">
                                <option value="test" ${g.mode === 'test' ? 'selected' : ''}>TEST Mode</option>
                                <option value="live" ${g.mode === 'live' ? 'selected' : ''}>LIVE Production Mode</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Razorpay Key ID</label>
                            <input type="text" id="gw-key-id" class="form-control" placeholder="rzp_test_xxxxxx" value="${g.key_id || ''}" required>
                        </div>
                        <div class="form-group">
                            <label>Razorpay Key Secret ${g.key_secret_configured ? '<span style="color:#16a34a; text-transform:none;">(Configured: ********)</span>' : '<span style="color:#dc2626; text-transform:none;">(Not Configured)</span>'}</label>
                            <input type="password" id="gw-key-secret" class="form-control" placeholder="Leave blank to keep existing key secret">
                        </div>
                        <div class="form-group">
                            <label>Razorpay Webhook Secret ${g.webhook_secret_configured ? '<span style="color:#16a34a; text-transform:none;">(Configured: ********)</span>' : '<span style="color:#64748b; text-transform:none;">(Optional)</span>'}</label>
                            <input type="password" id="gw-webhook-secret" class="form-control" placeholder="Leave blank to keep existing webhook secret">
                        </div>
                        <div class="form-group">
                            <label>Free Trial Period (Months)</label>
                            <input type="number" id="gw-trial" class="form-control" value="${g.trial_months || 3}" min="0" max="24" required>
                        </div>
                        <div style="display:flex; gap:12px; margin-top:24px;">
                            <button type="submit" class="btn-primary" style="flex:1;">Save Gateway Settings</button>
                            <button type="button" class="btn-sm" style="padding:12px 18px;" onclick="testGatewayConnection()">Test Connection</button>
                        </div>
                    </form>
                </div>
            `;
        }

        async function saveGatewaySettings(e) {
            e.preventDefault();
            const body = {
                key_id: document.getElementById('gw-key-id').value,
                mode: document.getElementById('gw-mode').value,
                currency: 'INR',
                active: document.getElementById('gw-active').value === '1',
                trial_months: parseInt(document.getElementById('gw-trial').value),
            };
            const sec = document.getElementById('gw-key-secret').value;
            const wh = document.getElementById('gw-webhook-secret').value;
            if (sec) body.key_secret = sec;
            if (wh) body.webhook_secret = wh;

            const res = await apiFetch('/settings/payment-gateway', 'POST', body);
            if (res && res.status === 'success') {
                alert('Razorpay Gateway Settings Saved Successfully!');
                loadGatewayView();
            } else {
                alert(res.message || 'Failed to save settings');
            }
        }

        async function testGatewayConnection() {
            const body = {
                key_id: document.getElementById('gw-key-id').value,
            };
            const sec = document.getElementById('gw-key-secret').value;
            if (sec) body.key_secret = sec;

            alert('Testing connection to Razorpay API...');
            const res = await apiFetch('/settings/payment-gateway/test', 'POST', body);
            if (res && res.success) {
                alert('SUCCESS: ' + res.message);
            } else {
                alert('FAILED: ' + (res.message || 'Authentication error'));
            }
        }

        // 9. SUPPORT VIEW
        async function loadSupportView(page = 1, search = '', status = '', type = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/support?page=${page}&search=${encodeURIComponent(search)}&status=${status}&type=${type}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const tickets = pageData.data || [];

            content.innerHTML = `
                <div class="card-table" style="padding:24px; margin-bottom:24px; max-width:850px;">
                    <h3 style="font-size:18px; font-weight:700; margin-bottom:6px;">💬 Mobile App Support Contact Settings</h3>
                    <p style="font-size:13px; color:#64748b; margin-bottom:16px;">Configure official support email, helpline phone number, and working hours displayed in the Mobile App Settings dialog.</p>
                    <form onsubmit="saveSupportContactInfo(event)" style="display:flex; flex-direction:column; gap:14px;">
                        <div style="display:flex; gap:16px; flex-wrap:wrap;">
                            <div class="form-group" style="flex:1; min-width:240px;">
                                <label style="font-size:12px; font-weight:600; color:#475569;">Official Support Email</label>
                                <input type="email" id="support_email" class="form-control" required placeholder="support@mobileprofits.com">
                            </div>
                            <div class="form-group" style="flex:1; min-width:240px;">
                                <label style="font-size:12px; font-weight:600; color:#475569;">Support Helpline Number</label>
                                <input type="text" id="support_phone" class="form-control" required placeholder="+91 98765 43210">
                            </div>
                        </div>
                        <div class="form-group">
                            <label style="font-size:12px; font-weight:600; color:#475569;">Support Working Hours</label>
                            <input type="text" id="support_hours" class="form-control" required placeholder="Mon - Sat: 9:00 AM - 8:00 PM IST">
                        </div>
                        <div>
                            <button type="submit" class="btn-primary" style="padding:10px 24px; border-radius:8px; font-weight:600;">Save Support Contact Details</button>
                        </div>
                    </form>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="support-search-input" placeholder="Search subject, message, shop..." value="${search}" oninput="debounceSearch(() => loadSupportView(1, document.getElementById('support-search-input').value, '${status}', '${type}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadSupportView(1, '${search}', this.value, '${type}')">
                                <option value="">Status: All</option>
                                <option value="open" ${status === 'open' ? 'selected' : ''}>Open</option>
                                <option value="in_progress" ${status === 'in_progress' ? 'selected' : ''}>In Progress</option>
                                <option value="resolved" ${status === 'resolved' ? 'selected' : ''}>Resolved</option>
                            </select>
                            <select class="filter-select" onchange="loadSupportView(1, '${search}', '${status}', this.value)">
                                <option value="">Type: All</option>
                                <option value="contact" ${type === 'contact' ? 'selected' : ''}>Contact</option>
                                <option value="problem" ${type === 'problem' ? 'selected' : ''}>Problem</option>
                                <option value="feedback" ${type === 'feedback' ? 'selected' : ''}>Feedback</option>
                            </select>
                            ${(search || status || type) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadSupportView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Type</th>
                                <th>Shop / Owner</th>
                                <th>Message</th>
                                <th>Date</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${tickets.length === 0 ? `<tr><td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No support tickets found matching filter criteria.</td></tr>` : ''}
                            ${tickets.map(t => `
                                <tr>
                                    <td><span class="badge badge-trial">${t.type}</span></td>
                                    <td><strong>${t.shop ? t.shop.name : 'Unknown Shop'}</strong></td>
                                    <td>${t.message}</td>
                                    <td>${new Date(t.created_at).toLocaleDateString()}</td>
                                    <td><span class="badge ${t.status === 'resolved' ? 'badge-resolved' : 'badge-inactive'}">${t.status}</span></td>
                                    <td>
                                        ${t.status !== 'resolved' ? `<button class="btn-sm btn-success-sm" onclick="resolveTicket(${t.id})">Mark Resolved</button>` : '—'}
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadSupportView', search, status, type)}
                </div>
            `;

            loadSupportContactInfo();
        }

        async function resolveTicket(id) {
            const data = await apiFetch(`/support/${id}/status`, 'PUT', { status: 'resolved' });
            if (data.success) {
                loadSupportView();
            }
        }

        async function loadSupportContactInfo() {
            const res = await apiFetch('/support/contact-info');
            if (res && res.success && res.data) {
                const info = res.data;
                if (document.getElementById('support_email')) document.getElementById('support_email').value = info.support_email || '';
                if (document.getElementById('support_phone')) document.getElementById('support_phone').value = info.support_phone || '';
                if (document.getElementById('support_hours')) document.getElementById('support_hours').value = info.support_hours || '';
            }
        }

        async function saveSupportContactInfo(e) {
            e.preventDefault();
            const email = document.getElementById('support_email').value;
            const phone = document.getElementById('support_phone').value;
            const hours = document.getElementById('support_hours').value;

            const res = await apiFetch('/support/contact-info', 'POST', {
                support_email: email,
                support_phone: phone,
                support_hours: hours
            });

            if (res && res.success) {
                alert('Official Support Contact Details Saved Successfully!');
                loadSupportContactInfo();
            } else {
                alert('Failed to save support details: ' + (res.message || 'Error'));
            }
        }

        // 10. AUDIT LOGS VIEW
        async function loadAuditView(page = 1, search = '', action = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/audit-logs?page=${page}&search=${encodeURIComponent(search)}&action=${action}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const logs = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="audit-search-input" placeholder="Search details, IP, admin name..." value="${search}" oninput="debounceSearch(() => loadAuditView(1, document.getElementById('audit-search-input').value, '${action}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadAuditView(1, '${search}', this.value)">
                                <option value="">Action: All Actions</option>
                                <option value="ACTIVATE_SHOP" ${action === 'ACTIVATE_SHOP' ? 'selected' : ''}>Activate Shop</option>
                                <option value="DEACTIVATE_SHOP" ${action === 'DEACTIVATE_SHOP' ? 'selected' : ''}>Deactivate Shop</option>
                                <option value="UPDATE_SUBSCRIPTION" ${action === 'UPDATE_SUBSCRIPTION' ? 'selected' : ''}>Update Subscription</option>
                                <option value="update_payment_gateway_settings" ${action === 'update_payment_gateway_settings' ? 'selected' : ''}>Update Gateway</option>
                                <option value="UPDATE_SUPPORT_STATUS" ${action === 'UPDATE_SUPPORT_STATUS' ? 'selected' : ''}>Support Status</option>
                            </select>
                            ${(search || action) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadAuditView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Admin User</th>
                                <th>Action Taken</th>
                                <th>Action Details</th>
                                <th>IP Address</th>
                                <th>Timestamp</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${logs.length === 0 ? `<tr><td colspan="5" style="text-align:center; padding:30px; color:#94a3b8;">No audit logs found matching filter criteria.</td></tr>` : ''}
                            ${logs.map(l => `
                                <tr>
                                    <td><strong>${l.admin ? l.admin.name : 'Admin System'}</strong></td>
                                    <td><span class="badge badge-resolved">${l.action}</span></td>
                                    <td>${l.details || '—'}</td>
                                    <td>${l.ip_address || '—'}</td>
                                    <td>${new Date(l.created_at).toLocaleString()}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadAuditView', search, action)}
                </div>
            `;
        }

        // 11. WEBSITE & LEGAL PAGES CMS VIEW
        async function loadPagesView() {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading dynamic legal pages...</div>';
            const data = await apiFetch('/pages');
            if (!data || !data.success) return;
            const pages = data.data || [];

            content.innerHTML = `
                <div style="margin-bottom:20px; display:flex; justify-content:space-between; align-items:center;">
                    <div>
                        <h2 style="font-size:18px; font-weight:700; color:#0f172a;">Website & Legal Pages</h2>
                        <p style="font-size:13px; color:#64748b; margin-top:2px;">Manage Privacy Policy, Terms & Conditions, Refund Policy, and Account Deletion content live on your website and Mobile App.</p>
                    </div>
                </div>
                <div class="card-table">
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Page Title</th>
                                <th>URL Slug</th>
                                <th>Status</th>
                                <th>Last Updated</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${pages.length === 0 ? `<tr><td colspan="5" style="text-align:center; padding:30px; color:#94a3b8;">No dynamic pages found.</td></tr>` : ''}
                            ${pages.map(p => `
                                <tr>
                                    <td><strong>${p.title}</strong></td>
                                    <td><code style="background:#f1f5f9; padding:2px 6px; border-radius:4px; font-size:12px; color:#0284c7;">/${p.slug}</code></td>
                                    <td>
                                        <span class="badge ${p.status === 'published' ? 'badge-active' : 'badge-inactive'}">${p.status}</span>
                                    </td>
                                    <td>${new Date(p.updated_at).toLocaleString()}</td>
                                    <td>
                                        <button class="btn-sm" style="background:#2563eb; color:white; border:none;" onclick="openEditPageModal('${p.slug}')">✏️ Edit Page</button>
                                        <a href="/${p.slug}" target="_blank" class="btn-sm" style="text-decoration:none; margin-left:4px;">🌐 View Live</a>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                </div>
            `;
        }

        async function openEditPageModal(slug) {
            const data = await apiFetch(`/pages/${slug}`);
            if (!data || !data.success) {
                alert('Failed to load page content.');
                return;
            }
            const page = data.data;

            const html = `
                <form id="edit-page-form" onsubmit="handleSavePage(event, '${slug}')">
                    <div class="form-group">
                        <label>Page Title *</label>
                        <input type="text" id="page-edit-title" class="form-control" value="${(page.title || '').replace(/"/g, '&quot;')}" required>
                    </div>
                    <div class="form-group">
                        <label>Meta Description (SEO)</label>
                        <input type="text" id="page-edit-meta" class="form-control" value="${(page.meta_description || '').replace(/"/g, '&quot;')}">
                    </div>
                    <div class="form-group">
                        <label>Publication Status *</label>
                        <select id="page-edit-status" class="form-control">
                            <option value="published" ${page.status === 'published' ? 'selected' : ''}>Published (Live on Website & Mobile App)</option>
                            <option value="draft" ${page.status === 'draft' ? 'selected' : ''}>Draft (Hidden)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Page HTML / Body Content *</label>
                        <textarea id="page-edit-content" class="form-control" rows="12" style="font-family:monospace; font-size:13px; line-height:1.5;" required>${(page.content || '')}</textarea>
                    </div>
                    <div style="display:flex; justify-content:flex-end; gap:10px; margin-top:20px;">
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                        <button type="submit" class="btn-primary" style="width:auto; padding:8px 20px;">Save & Publish Changes</button>
                    </div>
                </form>
            `;
            openModal(`Edit ${page.title} (/${slug})`, html);
        }

        async function handleSavePage(e, slug) {
            e.preventDefault();
            const title = document.getElementById('page-edit-title').value;
            const meta_description = document.getElementById('page-edit-meta').value;
            const status = document.getElementById('page-edit-status').value;
            const content = document.getElementById('page-edit-content').value;

            const res = await apiFetch(`/pages/${slug}`, 'PUT', { title, meta_description, status, content });
            if (res && res.success) {
                closeModal();
                alert('Page updated and published successfully! Live website and Flutter app updated.');
                loadPagesView();
            } else {
                alert(res.message || 'Error updating page.');
            }
        }

        // 12. SALES & INVOICES VIEW
        async function loadSalesView(page = 1, search = '', shopId = '', status = '', dateFrom = '', dateTo = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading sales records...</div>';

            const query = `/sales?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}&payment_status=${status}&date_from=${dateFrom}&date_to=${dateTo}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const sales = pageData.data || [];
            const sum = pageData.summary || { total_sales_amount: 0, total_paid_amount: 0, total_due_amount: 0, total_invoices_count: 0 };
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="grid-4">
                    <div class="metric-card">
                        <div class="metric-title">Total Invoices</div>
                        <div class="metric-value">${sum.total_invoices_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Gross Sales Amount</div>
                        <div class="metric-value">₹${sum.total_sales_amount.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Total Paid Amount</div>
                        <div class="metric-value" style="color:#16a34a;">₹${sum.total_paid_amount.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Outstanding Amount Due</div>
                        <div class="metric-value" style="color:#dc2626;">₹${sum.total_due_amount.toLocaleString()}</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="sales-search-input" placeholder="Search invoice #, customer, mobile, shop..." value="${search}" oninput="debounceSearch(() => loadSalesView(1, document.getElementById('sales-search-input').value, '${shopId}', '${status}', '${dateFrom}', '${dateTo}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadSalesView(1, '${search}', this.value, '${status}', '${dateFrom}', '${dateTo}')">
                                ${shopsOptions}
                            </select>
                            <select class="filter-select" onchange="loadSalesView(1, '${search}', '${shopId}', this.value, '${dateFrom}', '${dateTo}')">
                                <option value="">Payment Status: All</option>
                                <option value="paid" ${status === 'paid' ? 'selected' : ''}>Paid</option>
                                <option value="partially_paid" ${status === 'partially_paid' ? 'selected' : ''}>Partially Paid</option>
                                <option value="due" ${status === 'due' ? 'selected' : ''}>Due / Unpaid</option>
                            </select>
                            <input type="date" class="filter-select" value="${dateFrom}" title="From Date" onchange="loadSalesView(1, '${search}', '${shopId}', '${status}', this.value, '${dateTo}')">
                            <input type="date" class="filter-select" value="${dateTo}" title="To Date" onchange="loadSalesView(1, '${search}', '${shopId}', '${status}', '${dateFrom}', this.value)">
                            ${(search || shopId || status || dateFrom || dateTo) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadSalesView(1, '', '', '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Invoice #</th>
                                <th>Shop Name</th>
                                <th>Customer</th>
                                <th>Sale Date</th>
                                <th>Grand Total</th>
                                <th>Paid</th>
                                <th>Due</th>
                                <th>Payment Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${sales.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No sales records found matching criteria.</td></tr>` : ''}
                            ${sales.map(s => {
                                const stBadge = s.payment_status === 'paid' ? 'badge-active' : (s.payment_status === 'partially_paid' ? 'badge-trial' : 'badge-inactive');
                                return `
                                <tr>
                                    <td><strong><code style="color:#0284c7;">${s.invoice_number || 'INV-' + s.id}</code></strong></td>
                                    <td>${s.shop ? s.shop.name : 'Shop #' + s.shop_id}</td>
                                    <td><strong>${s.customer_name}</strong><br><span style="font-size:12px; color:#64748b;">${s.customer_mobile || ''}</span></td>
                                    <td>${new Date(s.sale_date || s.created_at).toLocaleDateString()}</td>
                                    <td><strong>₹${parseFloat(s.grand_total).toFixed(2)}</strong></td>
                                    <td style="color:#16a34a;">₹${parseFloat(s.amount_paid).toFixed(2)}</td>
                                    <td style="color:${s.amount_due > 0 ? '#dc2626' : '#64748b'};">₹${parseFloat(s.amount_due).toFixed(2)}</td>
                                    <td><span class="badge ${stBadge}">${(s.payment_status || 'due').replace('_', ' ').toUpperCase()}</span></td>
                                    <td><button class="btn-sm" onclick="openSaleDetails(${s.id})">Invoice Details</button></td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadSalesView', search, shopId, status, dateFrom, dateTo)}
                </div>
            `;
        }

        async function openSaleDetails(id) {
            const res = await apiFetch(`/sales/${id}`);
            if (!res || !res.success) return;
            const s = res.data;

            openModal(`Sale Invoice — ${s.invoice_number || 'INV-' + s.id}`, `
                <div style="font-size:13px; line-height:1.6;">
                    <div style="display:flex; justify-content:space-between; margin-bottom:14px; background:#f8fafc; padding:12px; border-radius:8px;">
                        <div>
                            <strong>Shop:</strong> ${s.shop ? s.shop.name : 'Shop #' + s.shop_id}<br>
                            <strong>Customer:</strong> ${s.customer_name} (${s.customer_mobile || 'N/A'})
                        </div>
                        <div style="text-align:right;">
                            <strong>Invoice Date:</strong> ${new Date(s.sale_date || s.created_at).toLocaleDateString()}<br>
                            <strong>Status:</strong> <span class="badge ${s.payment_status === 'paid' ? 'badge-active' : 'badge-trial'}">${(s.payment_status || '').toUpperCase()}</span>
                        </div>
                    </div>

                    <h4 style="font-size:12px; font-weight:700; text-transform:uppercase; color:#475569; margin-bottom:8px;">Line Items Purchased</h4>
                    <table style="width:100%; border-collapse:collapse; margin-bottom:14px;">
                        <thead>
                            <tr style="background:#f1f5f9;">
                                <th style="padding:6px; font-size:11px;">Item Description</th>
                                <th style="padding:6px; font-size:11px;">Qty</th>
                                <th style="padding:6px; font-size:11px;">Unit Price</th>
                                <th style="padding:6px; font-size:11px; text-align:right;">Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${(s.items || []).map(item => `
                                <tr>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${item.item_name}</td>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${item.quantity}</td>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0;">₹${parseFloat(item.unit_price).toFixed(2)}</td>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0; text-align:right;"><strong>₹${parseFloat(item.total_price).toFixed(2)}</strong></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>

                    <div style="display:flex; justify-content:flex-end; gap:20px; font-size:14px; margin-top:10px;">
                        <div>Subtotal: <strong>₹${parseFloat(s.subtotal).toFixed(2)}</strong></div>
                        <div>Discount: <strong>-₹${parseFloat(s.discount || 0).toFixed(2)}</strong></div>
                        <div>Grand Total: <strong style="color:#2563eb; font-size:16px;">₹${parseFloat(s.grand_total).toFixed(2)}</strong></div>
                    </div>
                </div>
            `);
        }

        // 13. REPAIRS VIEW
        async function loadRepairsView(page = 1, search = '', shopId = '', status = '', dateFrom = '', dateTo = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading repair job cards...</div>';

            const query = `/repairs?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}&status=${status}&date_from=${dateFrom}&date_to=${dateTo}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const repairs = pageData.data || [];
            const sum = pageData.summary || { total_count: 0, pending_count: 0, in_progress_count: 0, completed_count: 0, total_cost: 0, total_paid: 0 };
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="grid-4">
                    <div class="metric-card">
                        <div class="metric-title">Total Repair Jobs</div>
                        <div class="metric-value">${sum.total_count}</div>
                        <div class="metric-sub">${sum.pending_count} Pending | ${sum.in_progress_count} In Progress</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Completed & Delivered</div>
                        <div class="metric-value" style="color:#16a34a;">${sum.completed_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Total Repair Cost</div>
                        <div class="metric-value">₹${sum.total_cost.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Total Amount Paid</div>
                        <div class="metric-value" style="color:#10b981;">₹${sum.total_paid.toLocaleString()}</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="repairs-search-input" placeholder="Search job #, problem, device, customer, shop..." value="${search}" oninput="debounceSearch(() => loadRepairsView(1, document.getElementById('repairs-search-input').value, '${shopId}', '${status}', '${dateFrom}', '${dateTo}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadRepairsView(1, '${search}', this.value, '${status}', '${dateFrom}', '${dateTo}')">
                                ${shopsOptions}
                            </select>
                            <select class="filter-select" onchange="loadRepairsView(1, '${search}', '${shopId}', this.value, '${dateFrom}', '${dateTo}')">
                                <option value="">Status: All</option>
                                <option value="received" ${status === 'received' ? 'selected' : ''}>Received</option>
                                <option value="diagnosing" ${status === 'diagnosing' ? 'selected' : ''}>Diagnosing</option>
                                <option value="repairing" ${status === 'repairing' ? 'selected' : ''}>Repairing</option>
                                <option value="ready" ${status === 'ready' ? 'selected' : ''}>Ready for Pickup</option>
                                <option value="delivered" ${status === 'delivered' ? 'selected' : ''}>Delivered</option>
                                <option value="cancelled" ${status === 'cancelled' ? 'selected' : ''}>Cancelled</option>
                            </select>
                            <input type="date" class="filter-select" value="${dateFrom}" title="From Date" onchange="loadRepairsView(1, '${search}', '${shopId}', '${status}', this.value, '${dateTo}')">
                            <input type="date" class="filter-select" value="${dateTo}" title="To Date" onchange="loadRepairsView(1, '${search}', '${shopId}', '${status}', '${dateFrom}', this.value)">
                            ${(search || shopId || status || dateFrom || dateTo) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadRepairsView(1, '', '', '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Job #</th>
                                <th>Shop Name</th>
                                <th>Customer & Device</th>
                                <th>Problem Description</th>
                                <th>Received Date</th>
                                <th>Cost</th>
                                <th>Paid</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${repairs.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No repair jobs found matching criteria.</td></tr>` : ''}
                            ${repairs.map(r => {
                                const custName = r.customer ? r.customer.name : 'Unknown';
                                const devInfo = r.device ? `${r.device.brand || ''} ${r.device.model || ''}` : 'N/A';
                                const costVal = parseFloat(r.final_cost > 0 ? r.final_cost : r.estimated_cost);
                                const isDelivered = r.repair_status === 'delivered' || r.repair_status === 'ready';
                                return `
                                <tr>
                                    <td><strong><code style="color:#d97706;">${r.job_number || 'JOB-' + r.id}</code></strong></td>
                                    <td>${r.shop ? r.shop.name : 'Shop #' + r.shop_id}</td>
                                    <td><strong>${custName}</strong><br><span style="font-size:12px; color:#64748b;">📱 ${devInfo}</span></td>
                                    <td>${r.problem_description || '—'}</td>
                                    <td>${new Date(r.date_received || r.created_at).toLocaleDateString()}</td>
                                    <td><strong>₹${costVal.toFixed(2)}</strong></td>
                                    <td style="color:#16a34a;">₹${parseFloat(r.amount_paid).toFixed(2)}</td>
                                    <td><span class="badge ${isDelivered ? 'badge-active' : 'badge-trial'}">${(r.repair_status || '').toUpperCase()}</span></td>
                                    <td><button class="btn-sm" onclick="openRepairDetails(${r.id})">Job Details</button></td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadRepairsView', search, shopId, status, dateFrom, dateTo)}
                </div>
            `;
        }

        async function openRepairDetails(id) {
            const res = await apiFetch(`/repairs/${id}`);
            if (!res || !res.success) return;
            const r = res.data;

            const costVal = parseFloat(r.final_cost > 0 ? r.final_cost : r.estimated_cost);
            openModal(`Repair Job Card — ${r.job_number || 'JOB-' + r.id}`, `
                <div style="font-size:13px; line-height:1.6;">
                    <div style="display:flex; justify-content:space-between; margin-bottom:14px; background:#f8fafc; padding:12px; border-radius:8px;">
                        <div>
                            <strong>Shop:</strong> ${r.shop ? r.shop.name : 'Shop #' + r.shop_id}<br>
                            <strong>Customer:</strong> ${r.customer ? r.customer.name : 'N/A'} (${r.customer ? r.customer.mobile : 'N/A'})<br>
                            <strong>Device:</strong> ${r.device ? `${r.device.brand} ${r.device.model}` : 'N/A'}
                        </div>
                        <div style="text-align:right;">
                            <strong>Received Date:</strong> ${new Date(r.date_received || r.created_at).toLocaleDateString()}<br>
                            <strong>Status:</strong> <span class="badge badge-trial">${(r.repair_status || '').toUpperCase()}</span><br>
                            <strong>Technician:</strong> ${r.technician ? r.technician.name : 'Unassigned'}
                        </div>
                    </div>

                    <p><strong>Problem Description:</strong> ${r.problem_description || 'N/A'}</p>
                    <p><strong>Device Passcode / PIN:</strong> ${r.pin_passcode || 'None'}</p>
                    <p><strong>Condition Notes:</strong> ${r.condition_notes || 'N/A'}</p>
                    <hr style="margin:12px 0; border:0; border-top:1px solid #e2e8f0;">

                    <h4 style="font-size:12px; font-weight:700; text-transform:uppercase; color:#475569; margin-bottom:6px;">Spare Parts Used</h4>
                    <table style="width:100%; border-collapse:collapse; margin-bottom:12px;">
                        <thead>
                            <tr style="background:#f1f5f9;"><th style="padding:6px;">Part Name</th><th style="padding:6px;">Qty</th><th style="padding:6px; text-align:right;">Price</th></tr>
                        </thead>
                        <tbody>
                            ${(r.parts || []).length === 0 ? '<tr><td colspan="3" style="padding:6px; color:#94a3b8;">No spare parts logged for this job.</td></tr>' : ''}
                            ${(r.parts || []).map(p => `
                                <tr>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${p.part_name}</td>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${p.quantity}</td>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0; text-align:right;">₹${parseFloat(p.cost_price || p.price || 0).toFixed(2)}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>

                    <div style="display:flex; justify-content:flex-end; gap:20px; font-size:14px;">
                        <div>Labor Cost: <strong>₹${parseFloat(r.labour_cost || 0).toFixed(2)}</strong></div>
                        <div>Total Cost: <strong style="color:#d97706; font-size:16px;">₹${costVal.toFixed(2)}</strong></div>
                        <div>Amount Paid: <strong style="color:#16a34a; font-size:16px;">₹${parseFloat(r.amount_paid || 0).toFixed(2)}</strong></div>
                    </div>
                </div>
            `);
        }

        // 14. CUSTOMERS DIRECTORY VIEW
        async function loadCustomersView(page = 1, search = '', shopId = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading customer directory...</div>';

            const query = `/customers?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const customers = pageData.data || [];
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="customers-search-input" placeholder="Search customer name, mobile, email, shop..." value="${search}" oninput="debounceSearch(() => loadCustomersView(1, document.getElementById('customers-search-input').value, '${shopId}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadCustomersView(1, '${search}', this.value)">
                                ${shopsOptions}
                            </select>
                            ${(search || shopId) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadCustomersView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Customer Name</th>
                                <th>Mobile Number</th>
                                <th>Email / City</th>
                                <th>Associated Shop</th>
                                <th>Sales Invoices</th>
                                <th>Repairs Logged</th>
                                <th>Total Spent</th>
                                <th>Date Added</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${customers.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No customer records found matching criteria.</td></tr>` : ''}
                            ${customers.map(c => `
                                <tr>
                                    <td><strong>${c.name}</strong></td>
                                    <td>${c.mobile} ${c.alternate_mobile ? '<br><span style="font-size:11px; color:#64748b;">Alt: ' + c.alternate_mobile + '</span>' : ''}</td>
                                    <td>${c.email || '—'}<br><span style="font-size:11px; color:#64748b;">${c.city || ''}</span></td>
                                    <td>${c.shop ? c.shop.name : 'Shop #' + c.shop_id}</td>
                                    <td>${c.sales_count || 0}</td>
                                    <td>${c.repairs_count || 0}</td>
                                    <td><strong style="color:#2563eb;">₹${parseFloat(c.total_spent || 0).toFixed(2)}</strong></td>
                                    <td>${new Date(c.created_at).toLocaleDateString()}</td>
                                    <td><button class="btn-sm" onclick="openCustomerDetails(${c.id})">Customer Profile</button></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadCustomersView', search, shopId)}
                </div>
            `;
        }

        async function openCustomerDetails(id) {
            const res = await apiFetch(`/customers/${id}`);
            if (!res || !res.success) return;
            const c = res.data;

            openModal(`Customer Profile — ${c.name}`, `
                <div style="font-size:13px; line-height:1.6;">
                    <p><strong>Shop:</strong> ${c.shop ? c.shop.name : 'Shop #' + c.shop_id}</p>
                    <p><strong>Mobile:</strong> ${c.mobile} ${c.alternate_mobile ? ' | Alt: ' + c.alternate_mobile : ''}</p>
                    <p><strong>Email:</strong> ${c.email || 'N/A'} | <strong>City:</strong> ${c.city || 'N/A'}</p>
                    <p><strong>Total Lifetime Spent:</strong> <strong style="color:#16a34a; font-size:15px;">₹${parseFloat(c.total_spent || 0).toFixed(2)}</strong></p>
                    <hr style="margin:12px 0; border:0; border-top:1px solid #e2e8f0;">

                    <h4 style="font-size:13px; font-weight:700; margin-bottom:6px;">Registered Customer Devices (${(c.devices || []).length})</h4>
                    <ul style="list-style:none; padding:0; margin-bottom:14px;">
                        ${(c.devices || []).length === 0 ? '<li style="color:#94a3b8;">No devices registered.</li>' : ''}
                        ${(c.devices || []).map(d => `
                            <li style="background:#f8fafc; padding:6px 10px; border-radius:6px; margin-bottom:4px;">
                                📱 <strong>${d.brand} ${d.model}</strong> ${d.imei_serial ? `(IMEI/Serial: ${d.imei_serial})` : ''}
                            </li>
                        `).join('')}
                    </ul>

                    <h4 style="font-size:13px; font-weight:700; margin-bottom:6px;">Sales History (${(c.sales || []).length})</h4>
                    <ul style="list-style:none; padding:0; margin-bottom:14px;">
                        ${(c.sales || []).length === 0 ? '<li style="color:#94a3b8;">No sales history.</li>' : ''}
                        ${(c.sales || []).map(s => `
                            <li style="padding:6px; border-bottom:1px solid #e2e8f0; display:flex; justify-content:space-between;">
                                <span>Invoice #${s.invoice_number || s.id} — ${new Date(s.sale_date || s.created_at).toLocaleDateString()}</span>
                                <strong>₹${parseFloat(s.grand_total).toFixed(2)} (${s.payment_status})</strong>
                            </li>
                        `).join('')}
                    </ul>
                </div>
            `);
        }

        // 15. INVENTORY STOCK VIEW
        async function loadInventoryView(page = 1, search = '', shopId = '', lowStock = false, outOfStock = false) {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading inventory stock...</div>';

            const query = `/inventory?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}&low_stock=${lowStock ? 1 : 0}&out_of_stock=${outOfStock ? 1 : 0}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const items = pageData.data || [];
            const sum = pageData.summary || { total_items_count: 0, low_stock_count: 0, out_of_stock_count: 0, total_stock_value: 0, total_selling_value: 0 };
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="grid-4">
                    <div class="metric-card">
                        <div class="metric-title">Total Stock Items</div>
                        <div class="metric-value">${sum.total_items_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Stock Purchase Value</div>
                        <div class="metric-value">₹${sum.total_stock_value.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Stock Selling Value</div>
                        <div class="metric-value" style="color:#10b981;">₹${sum.total_selling_value.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Low / Out of Stock</div>
                        <div class="metric-value" style="color:#dc2626;">${sum.low_stock_count + sum.out_of_stock_count}</div>
                        <div class="metric-sub">${sum.low_stock_count} Low Stock | ${sum.out_of_stock_count} Out of Stock</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="inventory-search-input" placeholder="Search item name, SKU, brand, model, shop..." value="${search}" oninput="debounceSearch(() => loadInventoryView(1, document.getElementById('inventory-search-input').value, '${shopId}', ${lowStock}, ${outOfStock}))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadInventoryView(1, '${search}', this.value, ${lowStock}, ${outOfStock})">
                                ${shopsOptions}
                            </select>
                            <label style="font-size:13px; display:flex; align-items:center; gap:6px; cursor:pointer;">
                                <input type="checkbox" ${lowStock ? 'checked' : ''} onchange="loadInventoryView(1, '${search}', '${shopId}', this.checked, ${outOfStock})"> Low Stock Only
                            </label>
                            <label style="font-size:13px; display:flex; align-items:center; gap:6px; cursor:pointer;">
                                <input type="checkbox" ${outOfStock ? 'checked' : ''} onchange="loadInventoryView(1, '${search}', '${shopId}', ${lowStock}, this.checked)"> Out of Stock Only
                            </label>
                            ${(search || shopId || lowStock || outOfStock) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadInventoryView(1, '', '', false, false)">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Item Name</th>
                                <th>Shop Name</th>
                                <th>SKU / Category</th>
                                <th>Brand & Model</th>
                                <th>Current Stock</th>
                                <th>Min Stock</th>
                                <th>Cost Price</th>
                                <th>Selling Price</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${items.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No inventory items found matching criteria.</td></tr>` : ''}
                            ${items.map(i => {
                                const isLow = i.current_stock <= i.minimum_stock && i.current_stock > 0;
                                const isOut = i.current_stock <= 0;
                                const stBadge = isOut ? 'badge-inactive' : (isLow ? 'badge-trial' : 'badge-active');
                                return `
                                <tr>
                                    <td><strong>${i.name}</strong></td>
                                    <td>${i.shop ? i.shop.name : 'Shop #' + i.shop_id}</td>
                                    <td><code style="font-size:12px;">${i.sku || '—'}</code><br><span style="font-size:11px; color:#64748b;">${i.category || 'General'}</span></td>
                                    <td>${i.brand || '—'} ${i.model || ''}</td>
                                    <td><span class="badge ${stBadge}">${i.current_stock} ${i.unit || 'pcs'}</span></td>
                                    <td>${i.minimum_stock || 0}</td>
                                    <td>₹${parseFloat(i.purchase_price).toFixed(2)}</td>
                                    <td><strong>₹${parseFloat(i.selling_price).toFixed(2)}</strong></td>
                                    <td><button class="btn-sm" onclick="openInventoryDetails(${i.id})">Details</button></td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadInventoryView', search, shopId, lowStock, outOfStock)}
                </div>
            `;
        }

        async function openInventoryDetails(id) {
            const res = await apiFetch(`/inventory/${id}`);
            if (!res || !res.success) return;
            const item = res.data;

            openModal(`Stock Item — ${item.name}`, `
                <div style="font-size:13px; line-height:1.6;">
                    <p><strong>Shop:</strong> ${item.shop ? item.shop.name : 'Shop #' + item.shop_id}</p>
                    <p><strong>Category:</strong> ${item.category || 'N/A'} | <strong>Brand/Model:</strong> ${item.brand || ''} ${item.model || ''}</p>
                    <p><strong>SKU:</strong> <code>${item.sku || 'N/A'}</code></p>
                    <p><strong>Stock Level:</strong> ${item.current_stock} (Min threshold: ${item.minimum_stock})</p>
                    <p><strong>Purchase Cost:</strong> ₹${parseFloat(item.purchase_price).toFixed(2)} | <strong>Selling Price:</strong> ₹${parseFloat(item.selling_price).toFixed(2)}</p>
                    <hr style="margin:12px 0; border:0; border-top:1px solid #e2e8f0;">

                    <h4 style="font-size:13px; font-weight:700; margin-bottom:6px;">Stock Movement Logs</h4>
                    <ul style="list-style:none; padding:0;">
                        ${(item.stock_movements || []).length === 0 ? '<li style="color:#94a3b8;">No stock movement history recorded.</li>' : ''}
                        ${(item.stock_movements || []).map(m => `
                            <li style="padding:6px; border-bottom:1px solid #e2e8f0; display:flex; justify-content:space-between;">
                                <span>${m.movement_type.toUpperCase()} (${m.quantity > 0 ? '+' + m.quantity : m.quantity}) — ${m.reference_type || ''}</span>
                                <span style="font-size:11px; color:#64748b;">${new Date(m.created_at).toLocaleString()}</span>
                            </li>
                        `).join('')}
                    </ul>
                </div>
            `);
        }

        // 16. SHOP EXPENSES VIEW
        async function loadExpensesView(page = 1, search = '', shopId = '', categoryId = '', dateFrom = '', dateTo = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading shop expenses...</div>';

            const query = `/expenses?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}&category_id=${categoryId}&date_from=${dateFrom}&date_to=${dateTo}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const expenses = pageData.data || [];
            const sum = pageData.summary || { total_expense_amount: 0, expenses_count: 0 };
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="grid-4">
                    <div class="metric-card">
                        <div class="metric-title">Total Expenses Logged</div>
                        <div class="metric-value">${sum.expenses_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Total Expenses Amount</div>
                        <div class="metric-value" style="color:#dc2626;">₹${sum.total_expense_amount.toLocaleString()}</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="expenses-search-input" placeholder="Search expense title, category, reference, shop..." value="${search}" oninput="debounceSearch(() => loadExpensesView(1, document.getElementById('expenses-search-input').value, '${shopId}', '${categoryId}', '${dateFrom}', '${dateTo}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadExpensesView(1, '${search}', this.value, '${categoryId}', '${dateFrom}', '${dateTo}')">
                                ${shopsOptions}
                            </select>
                            <input type="date" class="filter-select" value="${dateFrom}" title="From Date" onchange="loadExpensesView(1, '${search}', '${shopId}', '${categoryId}', this.value, '${dateTo}')">
                            <input type="date" class="filter-select" value="${dateTo}" title="To Date" onchange="loadExpensesView(1, '${search}', '${shopId}', '${categoryId}', '${dateFrom}', this.value)">
                            ${(search || shopId || categoryId || dateFrom || dateTo) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadExpensesView(1, '', '', '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Expense Title</th>
                                <th>Shop Name</th>
                                <th>Category</th>
                                <th>Expense Date</th>
                                <th>Amount</th>
                                <th>Payment Method</th>
                                <th>Reference / Notes</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${expenses.length === 0 ? `<tr><td colspan="7" style="text-align:center; padding:30px; color:#94a3b8;">No shop expenses found matching criteria.</td></tr>` : ''}
                            ${expenses.map(e => `
                                <tr>
                                    <td><strong>${e.title}</strong></td>
                                    <td>${e.shop ? e.shop.name : 'Shop #' + e.shop_id}</td>
                                    <td><span class="badge badge-trial">${e.category ? e.category.name : 'General'}</span></td>
                                    <td>${new Date(e.expense_date || e.created_at).toLocaleDateString()}</td>
                                    <td><strong style="color:#dc2626;">₹${parseFloat(e.amount).toFixed(2)}</strong></td>
                                    <td>${e.payment_method || 'Cash'}</td>
                                    <td>${e.reference_number || e.notes || '—'}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadExpensesView', search, shopId, categoryId, dateFrom, dateTo)}
                </div>
            `;
        }

        // 17. WARRANTIES VIEW
        async function loadWarrantiesView(page = 1, search = '', shopId = '', status = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading warranties...</div>';

            const query = `/warranties?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}&status=${status}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const warranties = pageData.data || [];
            const sum = pageData.summary || { total_count: 0, active_count: 0 };
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="grid-4">
                    <div class="metric-card">
                        <div class="metric-title">Total Warranties</div>
                        <div class="metric-value">${sum.total_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Active Warranties</div>
                        <div class="metric-value" style="color:#16a34a;">${sum.active_count}</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="warranties-search-input" placeholder="Search warranty #, customer, shop..." value="${search}" oninput="debounceSearch(() => loadWarrantiesView(1, document.getElementById('warranties-search-input').value, '${shopId}', '${status}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadWarrantiesView(1, '${search}', this.value, '${status}')">
                                ${shopsOptions}
                            </select>
                            ${(search || shopId || status) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadWarrantiesView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Warranty #</th>
                                <th>Shop Name</th>
                                <th>Customer & Device</th>
                                <th>Start Date</th>
                                <th>End Date</th>
                                <th>Status</th>
                                <th>Claims Logged</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${warranties.length === 0 ? `<tr><td colspan="7" style="text-align:center; padding:30px; color:#94a3b8;">No warranty records found matching criteria.</td></tr>` : ''}
                            ${warranties.map(w => `
                                <tr>
                                    <td><strong><code>${w.warranty_number || 'WAR-' + w.id}</code></strong></td>
                                    <td>${w.shop ? w.shop.name : 'Shop #' + w.shop_id}</td>
                                    <td><strong>${w.customer ? w.customer.name : 'Unknown'}</strong><br><span style="font-size:11px; color:#64748b;">${w.device ? w.device.brand + ' ' + w.device.model : ''}</span></td>
                                    <td>${new Date(w.warranty_start_date).toLocaleDateString()}</td>
                                    <td>${new Date(w.warranty_end_date).toLocaleDateString()}</td>
                                    <td><span class="badge ${w.status === 'active' ? 'badge-active' : 'badge-inactive'}">${w.status}</span></td>
                                    <td>${(w.claims || []).length} Claims</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadWarrantiesView', search, shopId, status)}
                </div>
            `;
        }

        // 18. TECHNICIANS VIEW
        async function loadTechniciansView(page = 1, search = '', shopId = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading technicians directory...</div>';

            const query = `/technicians?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const techs = pageData.data || [];
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="techs-search-input" placeholder="Search technician name, mobile, specialization, shop..." value="${search}" oninput="debounceSearch(() => loadTechniciansView(1, document.getElementById('techs-search-input').value, '${shopId}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadTechniciansView(1, '${search}', this.value)">
                                ${shopsOptions}
                            </select>
                            ${(search || shopId) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadTechniciansView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Technician Name</th>
                                <th>Mobile Number</th>
                                <th>Specialization</th>
                                <th>Associated Shop</th>
                                <th>Total Jobs</th>
                                <th>Completed Jobs</th>
                                <th>Total Earnings</th>
                                <th>Total Paid</th>
                                <th>Payable Balance</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${techs.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No technicians found matching criteria.</td></tr>` : ''}
                            ${techs.map(t => `
                                <tr>
                                    <td><strong>${t.name}</strong></td>
                                    <td>${t.mobile}</td>
                                    <td>${t.specialization || 'General Repair'}</td>
                                    <td>${t.shop ? t.shop.name : 'Shop #' + t.shop_id}</td>
                                    <td>${t.total_jobs_count || 0}</td>
                                    <td>${t.completed_jobs_count || 0}</td>
                                    <td>₹${parseFloat(t.total_earnings || 0).toFixed(2)}</td>
                                    <td style="color:#16a34a;">₹${parseFloat(t.total_paid || 0).toFixed(2)}</td>
                                    <td><strong style="color:${t.total_payable > 0 ? '#d97706' : '#64748b'};">₹${parseFloat(t.total_payable || 0).toFixed(2)}</strong></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadTechniciansView', search, shopId)}
                </div>
            `;
        }

        // 19. PLATFORM BUSINESS INTELLIGENCE & FINANCIAL REPORTS VIEW
        async function loadReportsView(range = '30days', shopId = '', startDate = '', endDate = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Generating multi-dimensional platform business report...</div>';

            const query = `/reports/summary?date_range=${range}&shop_id=${shopId}&start_date=${startDate}&end_date=${endDate}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const rep = res.data;
            const fin = rep.financials;
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div style="margin-bottom:20px; background:white; padding:18px 24px; border-radius:12px; border:1px solid #e2e8f0; display:flex; gap:14px; flex-wrap:wrap; align-items:center; justify-content:space-between;">
                    <div>
                        <h3 style="font-size:16px; font-weight:700;">📊 Platform Business Analytics & Financial Matrix</h3>
                        <p style="font-size:13px; color:#64748b; margin-top:2px;">Aggregated financial reporting across all registered mobile shop businesses.</p>
                    </div>
                    <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                        <select class="filter-select" onchange="loadReportsView(this.value, '${shopId}', '${startDate}', '${endDate}')">
                            <option value="today" ${range === 'today' ? 'selected' : ''}>Today</option>
                            <option value="yesterday" ${range === 'yesterday' ? 'selected' : ''}>Yesterday</option>
                            <option value="7days" ${range === '7days' ? 'selected' : ''}>Last 7 Days</option>
                            <option value="30days" ${range === '30days' ? 'selected' : ''}>Last 30 Days</option>
                            <option value="this_month" ${range === 'this_month' ? 'selected' : ''}>This Month</option>
                            <option value="last_month" ${range === 'last_month' ? 'selected' : ''}>Last Month</option>
                            <option value="this_year" ${range === 'this_year' ? 'selected' : ''}>This Year</option>
                            <option value="all" ${range === 'all' ? 'selected' : ''}>All Time</option>
                        </select>
                        <select class="filter-select" onchange="loadReportsView('${range}', this.value, '${startDate}', '${endDate}')">
                            ${shopsOptions}
                        </select>
                    </div>
                </div>

                <div class="grid-4">
                    <div class="metric-card" style="border-left:4px solid #2563eb;">
                        <div class="metric-title">Gross Sales Revenue</div>
                        <div class="metric-value">₹${fin.total_sales_revenue.toLocaleString()}</div>
                        <div class="metric-sub">Paid: ₹${fin.total_sales_paid.toLocaleString()} | Due: ₹${fin.total_sales_due.toLocaleString()}</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #d97706;">
                        <div class="metric-title">Repairs Revenue</div>
                        <div class="metric-value">₹${fin.total_repair_cost.toLocaleString()}</div>
                        <div class="metric-sub">Paid: ₹${fin.total_repair_paid.toLocaleString()} | Due: ₹${fin.total_repair_due.toLocaleString()}</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #dc2626;">
                        <div class="metric-title">Total Shop Expenses</div>
                        <div class="metric-value" style="color:#dc2626;">₹${fin.total_shop_expenses.toLocaleString()}</div>
                        <div class="metric-sub">${rep.expenses.count} Expense Entries Logged</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #16a34a; background:#f0fdf4;">
                        <div class="metric-title" style="color:#166534;">Net Platform Business Profit</div>
                        <div class="metric-value" style="color:${fin.net_platform_profit >= 0 ? '#15803d' : '#b91c1c'};">₹${fin.net_platform_profit.toLocaleString()}</div>
                        <div class="metric-sub" style="color:#15803d;">Gross Income: ₹${fin.total_gross_income.toLocaleString()}</div>
                    </div>
                </div>

                <div style="display:grid; grid-template-columns:1fr 1fr; gap:20px; margin-bottom:24px;">
                    <div class="card-table" style="padding:20px;">
                        <h4 style="font-size:14px; font-weight:700; margin-bottom:12px;">🛒 Sales & Repairs Volume Breakdown</h4>
                        <div style="display:flex; justify-style:space-around; text-align:center; padding:14px; background:#f8fafc; border-radius:8px; margin-bottom:14px;">
                            <div>
                                <div style="font-size:22px; font-weight:700; color:#2563eb;">${rep.sales.count}</div>
                                <div style="font-size:12px; color:#64748b;">Sales Invoices</div>
                            </div>
                            <div>
                                <div style="font-size:22px; font-weight:700; color:#d97706;">${rep.repairs.count}</div>
                                <div style="font-size:12px; color:#64748b;">Repair Jobs</div>
                            </div>
                        </div>
                        <h5 style="font-size:12px; font-weight:700; text-transform:uppercase; color:#64748b; margin-bottom:8px;">Repair Status Summary</h5>
                        <div style="display:flex; gap:8px; flex-wrap:wrap;">
                            ${(rep.repairs.status_breakdown || []).map(sb => `
                                <span class="badge badge-trial" style="padding:6px 12px; font-size:12px;">
                                    ${sb.repair_status.toUpperCase()}: <strong>${sb.count}</strong>
                                </span>
                            `).join('')}
                        </div>
                    </div>

                    <div class="card-table" style="padding:20px;">
                        <h4 style="font-size:14px; font-weight:700; margin-bottom:12px;">📦 Inventory Stock Health & Valuation</h4>
                        <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-bottom:14px;">
                            <div style="background:#f8fafc; padding:10px; border-radius:8px;">
                                <div style="font-size:11px; color:#64748b; font-weight:600;">STOCK COST VALUATION</div>
                                <div style="font-size:18px; font-weight:700; color:#0f172a;">₹${rep.inventory.cost_valuation.toLocaleString()}</div>
                            </div>
                            <div style="background:#f8fafc; padding:10px; border-radius:8px;">
                                <div style="font-size:11px; color:#64748b; font-weight:600;">EXPECTED SELLING VALUATION</div>
                                <div style="font-size:18px; font-weight:700; color:#10b981;">₹${rep.inventory.selling_valuation.toLocaleString()}</div>
                            </div>
                        </div>
                        <div style="display:flex; gap:10px;">
                            <div style="flex:1; background:#fef3c7; padding:10px; border-radius:8px; color:#b45309; text-align:center;">
                                <strong>${rep.inventory.low_stock_count}</strong> Items Low in Stock
                            </div>
                            <div style="flex:1; background:#fee2e2; padding:10px; border-radius:8px; color:#b91c1c; text-align:center;">
                                <strong>${rep.inventory.out_of_stock_count}</strong> Items Out of Stock
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="font-weight:700; font-size:15px;">Shop-wise Financial Performance Comparison</div>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Owner</th>
                                <th>Sales Revenue</th>
                                <th>Repairs Revenue</th>
                                <th>Gross Revenue</th>
                                <th>Shop Expenses</th>
                                <th>Net Profit</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${(rep.shop_performance || []).length === 0 ? '<tr><td colspan="7" style="text-align:center; padding:30px; color:#94a3b8;">No shop activity recorded for selected range.</td></tr>' : ''}
                            ${(rep.shop_performance || []).map(sp => `
                                <tr>
                                    <td><strong>${sp.shop_name}</strong></td>
                                    <td>${sp.owner_name}</td>
                                    <td>₹${sp.sales_rev.toLocaleString()}</td>
                                    <td>₹${sp.repairs_rev.toLocaleString()}</td>
                                    <td><strong>₹${sp.gross_rev.toLocaleString()}</strong></td>
                                    <td style="color:#dc2626;">₹${sp.expenses.toLocaleString()}</td>
                                    <td><strong style="color:${sp.net_profit >= 0 ? '#16a34a' : '#dc2626'};">₹${sp.net_profit.toLocaleString()}</strong></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;
        }

        // MODAL HELPERS
        function openModal(title, htmlContent) {
            document.getElementById('modal-title').innerText = title;
            document.getElementById('modal-body').innerHTML = htmlContent;
            document.getElementById('modal-container').style.display = 'flex';
        }

        function closeModal() {
            document.getElementById('modal-container').style.display = 'none';
        }
    </script>
</body>
</html>
