-- LuaSnip for CP-optimized code snippets
return {
  'L3MON4D3/LuaSnip',
  version = 'v2.*',
  build = 'make install_jsregexp',
  dependencies = { 'rafamadriz/friendly-snippets' },
  config = function()
    local ls = require('luasnip')
    
    -- Load friendly-snippets (includes common language snippets)
    require('luasnip.loaders.from_vscode').lazy_load()
    
    -- CP-specific snippets for C++
    ls.add_snippets('cpp', {
      -- Fast I/O template
      ls.snippet('fastio', {
        ls.text_node({
          '/**',
          ' * Author: ',
        }),
        ls.insert_node(1, 'Harshit Sharma'),
        ls.text_node({
          '',
          ' * Date: ',
        }),
        ls.function_node(function() return os.date('%Y-%m-%d') end),
        ls.text_node({
          '',
          ' * Lang: C++23 (GCC 15)',
          ' * Goal: Top 1% | Candidate Master',
          ' */',
          '',
          '#include <bits/stdc++.h>',
          'using namespace std;',
          '',
          '// --- Type Aliases (Less Typing, More Thinking) ---',
          'using ll = long long;',
          'using ld = long double;',
          'using vi = vector<int>;',
          'using vll = vector<ll>;',
          'using pii = pair<int, int>;',
          'using pll = pair<ll, ll>;',
          'using vpii = vector<pii>;',
          '',
          '// --- Constants (No Magic Numbers) ---',
          'const ll MOD = 1e9 + 7;',
          'const ll INF = 1e18;',
          'const ld EPS = 1e-9;',
          '',
          '// --- Macros (Use with Care) ---',
          '#define all(x) (x).begin(), (x).end()',
          '#define rall(x) (x).rbegin(), (x).rend()',
          '#define pb push_back',
          '#define mp make_pair',
          '#define fi first',
          '#define se second',
          '#define sz(x) ((int)(x).size())',
          '#define yes cout << "YES" << endl',
          '#define no cout << "NO" << endl',
          '',
          '// --- Fast I/O (Crucial for TLE) ---',
          'void fast_io() {',
          '    ios_base::sync_with_stdio(false);',
          '    cin.tie(NULL);',
          '}',
          '',
          '// --- Solution Function ---',
          'void solve() {',
          '    ',
        }),
        ls.insert_node(0),
        ls.text_node({
          '',
          '}',
          '',
          '// --- Main Driver ---',
          'int main() {',
          '    fast_io();',
          '    ',
          '    int t = 1;',
          '    cin >> t; // Comment this out if only 1 test case exists',
          '    ',
          '    while (t--) {',
          '        solve();',
          '    }',
          '    ',
          '    return 0;',
          '}',
        }),
      }),
      
      -- Graph adjacency list
      ls.snippet('graph', {
        ls.text_node('vector<vector<int>> adj('),
        ls.insert_node(1, 'n'),
        ls.text_node(');'),
      }),
      
      -- DFS template
      ls.snippet('dfs', {
        ls.text_node({
          'vector<bool> vis(n, false);',
          'function<void(int)> dfs = [&](int u) {',
          '    vis[u] = true;',
          '    ',
        }),
        ls.insert_node(1),
        ls.text_node({
          '',
          '    for (int v : adj[u]) {',
          '        if (!vis[v]) dfs(v);',
          '    }',
          '};',
        }),
      }),
      
      -- Binary search template
      ls.snippet('binsearch', {
        ls.text_node({
          'int lo = ',
        }),
        ls.insert_node(1, '0'),
        ls.text_node(', hi = '),
        ls.insert_node(2, 'n'),
        ls.text_node({
          ';',
          'while (lo < hi) {',
          '    int mid = lo + (hi - lo) / 2;',
          '    if (',
        }),
        ls.insert_node(3, 'condition'),
        ls.text_node({
          ') {',
          '        hi = mid;',
          '    } else {',
          '        lo = mid + 1;',
          '    }',
          '}',
        }),
      }),
      
      -- Modular arithmetic
      ls.snippet('mod', {
        ls.text_node({
          'const int MOD = 1e9 + 7;',
          'auto add = [](long long a, long long b) { return (a + b) % MOD; };',
          'auto mul = [](long long a, long long b) { return (a * b) % MOD; };',
        }),
      }),
    })
    
    -- Keybindings for snippet navigation
    vim.keymap.set({ 'i', 's' }, '<C-k>', function()
      if ls.expand_or_jumpable() then
        ls.expand_or_jump()
      end
    end, { silent = true, desc = 'LuaSnip: Expand or jump' })
    
    vim.keymap.set({ 'i', 's' }, '<C-j>', function()
      if ls.jumpable(-1) then
        ls.jump(-1)
      end
    end, { silent = true, desc = 'LuaSnip: Jump back' })
  end,
}
