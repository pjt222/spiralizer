# Spiralizer UI Design

## Design Philosophy

> "In the void, patterns emerge. In simplicity, beauty thrives."

Spiralizer follows an **artistic minimalist** approach where the mathematical visualization is the protagonist. The UI serves the artwork, never competing with it.

## Core Principles

### 1. Spiral-First Design
The Voronoi visualization fills the viewport. All other elements are secondary, collapsible, and unobtrusive.

### 2. Disappearing Interface
Controls exist in a collapsible sidebar. When collapsed, the spiral artwork occupies 100% of the screen - perfect for contemplation or screenshots.

### 3. Restrained Aesthetics
Dark backgrounds, minimal color palette, subtle animations. Visual noise is eliminated.

### 4. Responsive Intelligence
The interface adapts to context: sidebar collapses on mobile, performance adjusts to hardware capabilities.

## Visual Language

### Color Philosophy

| Color | Hex | Purpose | Emotion |
|-------|-----|---------|---------|
| **Deep Space** | `#0a0a0a` | Background | Void, infinite depth |
| **Soft White** | `#e0e0e0` | Text | Clarity without harshness |
| **Ethereal Green** | `#00ff88` | Accent | Growth, emergence, life |
| **Mid Gray** | `#2a2a2a` | Borders | Structure without dominance |

### Typography

- **Font**: Inter (variable weight 300-600)
- **Style**: Light weight (300) for body, medium (500) for emphasis
- **Labels**: Uppercase, small, letter-spaced (0.1em)
- **Aesthetic**: Technical, precise, unadorned

### Spacing

Based on 8px grid:
- **Component margins**: 16px (2 units)
- **Card padding**: 16px
- **Section gaps**: 24px (3 units)
- **Sidebar width**: 320px (40 units)

## Layout Structure

```
Desktop (>768px)                    Mobile (<768px)
┌────────┬───────────────────┐     ┌───────────────────┐
│        │                   │     │   SPIRAL          │
│ SIDEBAR│     SPIRAL        │     │   (full screen)   │
│ (320px)│  (fills space)    │     │                   │
│        │                   │     │                   │
│ [open] │                   │     ├───────────────────┤
│        │                   │     │ [≡] tap to open   │
└────────┴───────────────────┘     └───────────────────┘
```

### Sidebar States

**Open** (default on desktop):
- 320px fixed width
- Glass-morphism background
- All controls visible
- Scrollable if content overflows

**Collapsed** (default on mobile):
- Toggle button visible
- Spiral fills 100% viewport
- One-click to expand

## Component Design

### Cards

Cards group related controls with minimal visual weight:

```
┌──────────────────────────┐
│ SPIRAL SHAPE             │  ← Header: uppercase, small, muted
├──────────────────────────┤
│ Start        [━━━●━━━] 0 │  ← Slider with value display
│ End          [━━━━━●─] 100│
│ Density      [━━━●━━━] 300│
└──────────────────────────┘
```

- **Border**: 1px solid, subtle gray
- **Background**: Slightly lighter than page
- **Header**: Minimal, no background
- **Padding**: Consistent 16px

### Sliders

```
Label               Value
Start         ────●──── 100
             ↑
      Subtle track, glowing thumb on hover
```

- **Track**: Thin, low contrast
- **Thumb**: 16px diameter, glows green on hover
- **Value display**: Right-aligned, monospace, accent color

### Buttons

**Preset buttons** (2x2 grid):
```
┌─────────┐ ┌─────────┐
│ Simple  │ │ Classic │
├─────────┤ ├─────────┤
│ Complex │ │Ethereal │
└─────────┘ └─────────┘
┌─────────────────────┐
│   🎲  Random        │
└─────────────────────┘
```

- **Style**: Outline, small size
- **Hover**: Border glows accent color
- **Active**: Filled with accent color

**Export buttons**:
```
┌──────┐ ┌──────┐
│ PNG  │ │ SVG  │
└──────┘ └──────┘
```

- **Style**: Outline light, small
- **Position**: Within sidebar or floating

### Color Palette Selector

```
Color
┌─────────────────────────┐
│ Turbo                 ▼ │
└─────────────────────────┘
```

- **Dropdown**: Bootstrap-styled with dark theme
- **Options**: Text labels (no color swatches needed)

## Animations

### Idle Breathing
After 30 seconds of inactivity, the spiral container subtly "breathes":
```css
animation: zen-breathe 4s ease-in-out infinite;
/* Opacity 1 → 0.95, Scale 1 → 1.002 */
```

### Performance Indicator Pulse
```css
animation: pulse 2s infinite;
/* Opacity 1 → 0.5 → 1 */
```

### Hover Glow
Buttons and sliders glow on hover:
```css
box-shadow: 0 0 20px rgba(0, 255, 136, 0.3);
```

### Transitions
All state changes use cubic-bezier easing:
```css
transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
```

## Interaction Design

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `?` | Toggle shortcuts help |
| `R` | Random pattern |
| `D` | Default pattern |
| `F` | Fullscreen |
| `E` | Export PNG |

### Touch Interactions
- **Slider drag**: Native touch support
- **Sidebar toggle**: Tap hamburger icon
- **Scroll**: Sidebar content scrolls independently

### Feedback

**Loading state**:
- Spinner overlay on plot
- Subtle opacity reduction

**Computation feedback**:
- Performance indicator shows ms and cell count
- Color-coded: green (fast), yellow (moderate), red (slow)

**Validation errors**:
- Toast notification
- Auto-dismiss after 3 seconds

## Accessibility

### Color Contrast
- Text on background: 13:1 (`#e0e0e0` on `#0a0a0a`)
- Accent on background: 8:1 (`#00ff88` on `#0a0a0a`)

### Focus States
- Visible focus rings on all interactive elements
- Keyboard navigation fully supported

### Reduced Motion
```css
@media (prefers-reduced-motion: reduce) {
  * { animation: none !important; }
}
```

### Screen Reader Support
- Semantic HTML structure
- ARIA labels on interactive elements
- Logical tab order

## Future Considerations

### Potential Enhancements
- Gallery mode for saved patterns
- Full-screen presentation mode
- Pattern sharing via URL
- Custom color palette builder

### Design System Evolution
- Additional themes (light mode, high contrast)
- Component library for extensions
- Design tokens for consistency

## Design Inspiration

- **Gallery websites**: Minimal chrome, content-forward
- **Meditation apps**: Breathing animations, calm aesthetics
- **Creative coding tools**: Technical precision, generative art focus
- **Terminal UIs**: Monospace typography, stark contrast
