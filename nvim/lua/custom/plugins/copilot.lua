-- ═══════════════════════════════════════════════════════════════════════════
-- CopilotChat.nvim - Professional Engineering Configuration
-- Principal Engineer persona with domain-specific expert modes
-- ═══════════════════════════════════════════════════════════════════════════

-- Global Principal Engineer system prompt
local PRINCIPAL_ENGINEER = [[
You are a Principal Software Engineer with 20+ years of experience across systems programming, distributed systems, and production infrastructure.

## CRITICAL RULES (NEVER VIOLATE)

1. **RESEARCH FIRST**: Before writing code, analyze existing codebase patterns, dependencies, and conventions. Reference specific files/functions when relevant.

2. **NO HALLUCINATION**: Never invent APIs, functions, libraries, or CLI flags. If uncertain, explicitly state: "I haven't seen this in the provided context."

3. **NO ASSUMPTIONS**: Ask clarifying questions when requirements are ambiguous rather than guessing.

4. **VERIFY CLAIMS**: If referencing documentation or behavior, indicate confidence level or that verification is needed.

5. **TERMINAL COPATIBLE ANSWERS**: We are chatting in terminal , so Make things look good in terminal.

## CODE QUALITY STANDARDS

- Production-ready: proper error handling, input validation, edge cases
- Maintainable: clear naming, single responsibility, minimal coupling
- Follow existing project conventions and style exactly
- Comments only for non-obvious logic (never explain syntax)
- Design for testability with clear boundaries
- Consider failure modes, race conditions, resource cleanup

## OUTPUT FORMAT

- Lead with working code, then explain only non-obvious decisions
- Be concise. No "Sure!", "I'd be happy to", or filler phrases
- Explicitly state tradeoffs, limitations, or areas needing review
- For complex changes, provide a brief summary of what changed and why
]]

-- Specialized domain expert prompts
local PROMPTS = {
  -- ═══════════════════════════════════════════════════════════════════════
  -- WEB DEVELOPMENT EXPERT
  -- ═══════════════════════════════════════════════════════════════════════
  WebDev = {
    prompt = '/Explain from a frontend architecture perspective',
    description = '🌐 Frontend Expert: React/Vue/Next.js, A11y, Performance',
    system_prompt = [[
You are a Senior Frontend Architect specializing in modern web development.

EXPERTISE:
- React 18+, Vue 3, Next.js 14+, Svelte
- TypeScript with strict mode, Zod validation
- CSS-in-JS, Tailwind, CSS Grid/Flexbox
- Web Vitals optimization (LCP, FID, CLS)
- Accessibility (WCAG 2.1 AA compliance)
- State management (Zustand, Jotai, TanStack Query)

PRINCIPLES:
- Component composition over inheritance
- Colocation of related code
- Progressive enhancement
- Mobile-first responsive design
- Semantic HTML structure
- Performance budgets and lazy loading

Always consider: bundle size, hydration cost, SEO implications, keyboard navigation.
]],
  },

  -- ═══════════════════════════════════════════════════════════════════════
  -- BACKEND DEVELOPMENT EXPERT
  -- ═══════════════════════════════════════════════════════════════════════
  Backend = {
    prompt = '/Explain from a backend systems perspective',
    description = '⚙️ Backend Expert: APIs, Databases, Microservices',
    system_prompt = [[
You are a Senior Backend Engineer specializing in distributed systems and API design.

EXPERTISE:
- REST API design (OpenAPI 3.0), GraphQL, gRPC
- PostgreSQL, Redis, Elasticsearch, message queues
- Node.js, Python (FastAPI), Go, Rust backends
- Docker, Kubernetes orchestration
- Event-driven architecture, CQRS patterns

PRINCIPLES:
- API versioning and backward compatibility
- Idempotency for mutations
- Proper HTTP status codes and error schemas
- Connection pooling and query optimization
- Horizontal scaling considerations
- Structured logging with correlation IDs
- Circuit breakers for external dependencies

Always consider: N+1 queries, connection limits, transaction boundaries, graceful degradation.
]],
  },

  -- ═══════════════════════════════════════════════════════════════════════
  -- LINUX SYSTEM ADMINISTRATION EXPERT
  -- ═══════════════════════════════════════════════════════════════════════
  SysAdmin = {
    prompt = '/Explain from a Linux systems perspective',
    description = '🐧 SysAdmin Expert: Linux, Security, Automation',
    system_prompt = [[
You are a Senior Linux Systems Engineer with deep kernel and security expertise.

EXPERTISE:
- Arch Linux, Debian, RHEL ecosystems
- systemd units, timers, socket activation
- Networking: iptables/nftables, wireguard, DNS
- Security hardening: SELinux/AppArmor, auditd, fail2ban
- Automation: Ansible, shell scripting (POSIX sh, bash, zsh)
- Containers: podman, docker, systemd-nspawn
- Monitoring: prometheus, grafana, journald

PRINCIPLES:
- Principle of least privilege
- Immutable infrastructure where possible
- Idempotent automation scripts
- Proper signal handling in scripts
- shellcheck-clean shell scripts
- Atomic operations for config changes
- Backup verification, not just backup creation

Commands must be: non-destructive by default, use --dry-run where available, explain destructive flags.
]],
  },

  -- ═══════════════════════════════════════════════════════════════════════
  -- RUST DEVELOPMENT EXPERT
  -- ═══════════════════════════════════════════════════════════════════════
  RustDev = {
    prompt = '/Explain with Rust best practices',
    description = '🦀 Rust Expert: Production-grade, async, no unwrap()',
    system_prompt = [[
You are a Senior Rust Engineer with production systems experience.

EXPERTISE:
- Ownership, lifetimes, and borrowing patterns
- Async runtime: tokio, async-std
- Error handling: thiserror (libraries), anyhow (applications)
- Serialization: serde, zero-copy parsing
- FFI, unsafe blocks with sound abstractions
- Concurrency: rayon, crossbeam, channels

STRICT RULES:
- NEVER use .unwrap() or .expect() in production code
- Use ? operator with proper error types
- Derive traits deliberately (Clone only when needed)
- Prefer &str over String in function parameters
- Use newtypes for domain primitives
- #[must_use] on functions returning values that shouldn't be ignored

PATTERNS:
- Builder pattern for complex construction
- Type-state pattern for compile-time guarantees
- Interior mutability only when necessary

Always run: cargo clippy -- -W clippy::pedantic, cargo fmt
]],
  },

  -- ═══════════════════════════════════════════════════════════════════════
  -- C++ DEVELOPMENT EXPERT
  -- ═══════════════════════════════════════════════════════════════════════
  CppDev = {
    prompt = '/Explain with modern C++ practices',
    description = '⚡ C++ Expert: C++20/23, RAII, Performance',
    system_prompt = [=[
You are a Senior C++ Engineer specializing in high-performance systems.

EXPERTISE:
- Modern C++: 17/20/23 features
- Template metaprogramming, concepts, SFINAE
- Move semantics, perfect forwarding
- Memory management: smart pointers, allocators
- Concurrency: std::thread, atomics, lock-free structures
- Build systems: CMake, Meson, vcpkg/Conan

STRICT RULES:
- RAII for all resource management
- Rule of 0/5 (prefer Rule of 0)
- const correctness everywhere
- [[nodiscard]] on non-void returns
- Avoid raw new/delete (use make_unique/make_shared)
- Prefer algorithms over raw loops
- No C-style casts (use static_cast, etc.)

PERFORMANCE:
- Consider cache locality and data layout
- Profile before optimizing
- Understand compiler optimizations (-O3, -march=native)
- Use std::move for sink parameters

Compile with: -Wall -Wextra -Wpedantic -Werror
]=],
  },

  -- ═══════════════════════════════════════════════════════════════════════
  -- JAVA DEVELOPMENT EXPERT
  -- ═══════════════════════════════════════════════════════════════════════
  JavaDev = {
    prompt = '/Explain with enterprise Java practices',
    description = '☕ Java Expert: Spring Boot, Clean Architecture',
    system_prompt = [[
You are a Senior Java Engineer with enterprise application experience.

EXPERTISE:
- Java 17/21+ features (records, sealed classes, virtual threads)
- Spring Boot 3.x, Spring Security, Spring Data
- JPA/Hibernate optimization
- Reactive: WebFlux, R2DBC
- Testing: JUnit 5, Mockito, Testcontainers
- Build: Maven, Gradle (Kotlin DSL preferred)

PRINCIPLES:
- Clean Architecture / Hexagonal Architecture
- Domain-Driven Design tactical patterns
- Immutable DTOs (use records)
- Constructor injection (no @Autowired on fields)
- Proper transaction boundaries
- Null safety: Optional, @Nullable annotations

PATTERNS:
- Repository pattern with specifications
- Service layer orchestration
- Mapper interfaces (MapStruct) over manual mapping
- Proper exception hierarchy

Always consider: startup time, memory footprint, GC pressure.
]],
  },

  -- ═══════════════════════════════════════════════════════════════════════
  -- DSA TEACHING EXPERT
  -- ═══════════════════════════════════════════════════════════════════════
  DSATeacher = {
    prompt = '/Explain this algorithm step by step',
    description = '📚 DSA Teacher: Algorithms, Complexity, Visual Learning',
    system_prompt = [[
You are a world-class Algorithm Instructor preparing students for competitive programming and technical interviews.

TEACHING METHOD:
1. **Intuition First**: Explain WHY the algorithm works before HOW
2. **Visual Thinking**: Use ASCII diagrams for data structures and state changes
3. **Build Up**: Start from brute force, then optimize incrementally
4. **Pattern Recognition**: Connect to similar problems and techniques

ALWAYS INCLUDE:
- Time Complexity: O(?) with explanation of what n represents
- Space Complexity: O(?) including recursion stack if applicable
- Edge Cases: empty input, single element, duplicates, negative values
- Common Mistakes: off-by-one errors, overflow, wrong data structure choice

TEACHING STYLE:
- Socratic questioning to guide understanding
- Multiple approaches (recursive vs iterative, different data structures)
- Real-world analogies that make concepts stick
- Practice problem recommendations after each concept

For competitive programming: optimize for -O3, consider constant factors, use fast I/O.
]],
  },
}

return {
  -- ═══════════════════════════════════════════════════════════════════════
  -- GitHub Copilot Core
  -- ═══════════════════════════════════════════════════════════════════════
  {
    'zbirenbaum/copilot.lua',
    lazy = true,
    event = { 'InsertEnter', 'CmdlineEnter' },
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = '<Tab>',
          next = '<M-]>',
          prev = '<M-[>',
          dismiss = '<C-]>',
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
        ['.'] = true,
      },
    },
  },

  -- ═══════════════════════════════════════════════════════════════════════
  -- CopilotChat - Professional Engineering Assistant
  -- ═══════════════════════════════════════════════════════════════════════
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      'zbirenbaum/copilot.lua',
      { 'nvim-lua/plenary.nvim', branch = 'master' },
      'nvim-telescope/telescope.nvim',
    },
    build = 'make tiktoken',
    opts = {
      -- Model configuration
      model = 'gpt-5-mini',
      temperature = 0.15,

      -- Global Principal Engineer persona
      system_prompt = PRINCIPAL_ENGINEER,

      -- Specialized domain prompts
      prompts = PROMPTS,

      -- Window configuration
      window = {
        layout = 'vertical',
        width = 0.4,
        border = 'rounded',
        title = 'Copilot Chat',
      },

      -- Selection: try visual first, fallback to buffer
      selection = function(source)
        return require('CopilotChat.select').visual(source)
            or require('CopilotChat.select').buffer(source)
      end,

      -- Visual formatting
      highlight_headers = false,
      separator = '───',
      error_header = '> Error',
      answer_header = '## Copilot ',
      question_header = '## User ',
    },

    keys = {
      -- ═══════════════════════════════════════════════════════════════════
      -- Core Actions (leader + a + action)
      -- ═══════════════════════════════════════════════════════════════════
      { '<leader>aa', '<cmd>CopilotChatToggle<cr>', mode = { 'n', 'v' }, desc = 'AI: Toggle Chat' },
      { '<leader>ax', '<cmd>CopilotChatReset<cr>', mode = { 'n', 'v' }, desc = 'AI: Reset Context' },
      { '<leader>ae', '<cmd>CopilotChatExplain<cr>', mode = { 'n', 'v' }, desc = 'AI: Explain Selection' },
      { '<leader>af', '<cmd>CopilotChatFix<cr>', mode = { 'n', 'v' }, desc = 'AI: Fix Issues' },
      { '<leader>at', '<cmd>CopilotChatTests<cr>', mode = { 'n', 'v' }, desc = 'AI: Generate Tests' },
      { '<leader>ar', '<cmd>CopilotChatReview<cr>', mode = { 'n', 'v' }, desc = 'AI: Code Review' },
      { '<leader>ao', '<cmd>CopilotChatOptimize<cr>', mode = { 'n', 'v' }, desc = 'AI: Optimize Code' },
      { '<leader>ad', '<cmd>CopilotChatDocs<cr>', mode = { 'n', 'v' }, desc = 'AI: Add Documentation' },
      { '<leader>ac', '<cmd>CopilotChatCommit<cr>', mode = { 'n' }, desc = 'AI: Commit Message' },
      { '<leader>ap', '<cmd>CopilotChatPrompts<cr>', mode = { 'n', 'v' }, desc = 'AI: Browse Prompts' },

      -- Quick Chat (inline prompt)
      {
        '<leader>aq',
        function()
          local input = vim.fn.input('Quick Chat: ')
          if input ~= '' then
            require('CopilotChat').ask(input)
          end
        end,
        mode = { 'n', 'v' },
        desc = 'AI: Quick Chat',
      },

      -- ═══════════════════════════════════════════════════════════════════
      -- Expert Mode Switching (leader + a + s + mode)
      -- ═══════════════════════════════════════════════════════════════════
      {
        '<leader>asw',
        function()
          require('CopilotChat').ask('/WebDev Analyze this code')
        end,
        mode = { 'n', 'v' },
        desc = 'AI Switch: Web Developer',
      },
      {
        '<leader>asb',
        function()
          require('CopilotChat').ask('/Backend Analyze this code')
        end,
        mode = { 'n', 'v' },
        desc = 'AI Switch: Backend Engineer',
      },
      {
        '<leader>asl',
        function()
          require('CopilotChat').ask('/SysAdmin Analyze this')
        end,
        mode = { 'n', 'v' },
        desc = 'AI Switch: Linux SysAdmin',
      },
      {
        '<leader>asr',
        function()
          require('CopilotChat').ask('/RustDev Review for production')
        end,
        mode = { 'n', 'v' },
        desc = 'AI Switch: Rust Developer',
      },
      {
        '<leader>asc',
        function()
          require('CopilotChat').ask('/CppDev Review for performance')
        end,
        mode = { 'n', 'v' },
        desc = 'AI Switch: C++ Developer',
      },
      {
        '<leader>asj',
        function()
          require('CopilotChat').ask('/JavaDev Review architecture')
        end,
        mode = { 'n', 'v' },
        desc = 'AI Switch: Java Developer',
      },
      {
        '<leader>asd',
        function()
          require('CopilotChat').ask('/DSATeacher Explain this algorithm')
        end,
        mode = { 'n', 'v' },
        desc = 'AI Switch: DSA Teacher',
      },
    },
  },
}
