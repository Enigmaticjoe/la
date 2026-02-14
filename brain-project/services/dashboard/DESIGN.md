# 🎨 Brain AI Dashboard - Design Specification

## Color Palette

### Primary Colors
```css
--primary-glow: #00ff9f     /* Neon Green - Success, Primary Actions */
--secondary-glow: #00d4ff   /* Neon Cyan - Info, Links */
--danger-glow: #ff006e      /* Neon Pink - Errors, Critical */
--warning-glow: #ffbe0b     /* Neon Yellow - Warnings */
```

### Background Colors
```css
--bg-dark: #0a0e27          /* Main Dark Background */
--bg-darker: #050818        /* Darker Sections */
--bg-card: rgba(15, 23, 42, 0.8)  /* Card Background (Glassmorphism) */
```

### Gradients
```css
/* Header & Cards */
background: linear-gradient(135deg, #0a0e27 0%, #1a1f3a 50%, #0a0e27 100%);

/* Buttons & Progress Bars */
background: linear-gradient(90deg, #00ff9f, #00d4ff);

/* Status Indicators */
Critical: linear-gradient(90deg, #ff006e, #ff4500);
Warning: linear-gradient(90deg, #ffbe0b, #ffa500);
Normal: linear-gradient(90deg, #00ff9f, #00d4ff);
```

## Typography

### Fonts
- **Display (Headers):** Orbitron - Bold, Futuristic, Sci-Fi
- **Body (Content):** Rajdhani - Clean, Modern, Readable

### Font Sizes
```css
.title: 2.5rem (40px)           /* Main Header */
.section-title: 1.8rem (29px)   /* Section Headers */
.metric-value: 1.8rem (29px)    /* Large Numbers */
.service-name: 1.2rem (19px)    /* Service Names */
body: 1rem (16px)               /* Default Text */
.metric-label: 0.9rem (14px)    /* Small Labels */
```

## Layout Grid

### Desktop (1200px+)
```
+------------------+------------------+
|                                     |
|              HEADER                 |
|                                     |
+------------------+------------------+
| GPU Temp | VRAM  |  CPU   |  RAM    |  <- Metrics (4 cols)
+------------------+------------------+
|                                     |
|         AI SERVICES (3 cols)        |  <- Service cards
|                                     |
+------------------+------------------+
|   System Info    | Alerts & Notif   |  <- Info section (2 cols)
+------------------+------------------+
|              FOOTER                 |
+-------------------------------------+
```

### Tablet (768px - 1199px)
- Metrics: 2 columns
- Services: 2 columns
- Info: 1 column (stacked)

### Mobile (< 768px)
- All sections: 1 column
- Header: Stacked vertically
- Services: Full width cards

## Components

### Service Card
```
┌─────────────────────────────────────┐
│ 🤖  vLLM Inference     [ONLINE]     │  <- Header
├─────────────────────────────────────┤
│ Large Language Model Inference      │  <- Description
├─────────────────────────────────────┤
│  Latency        Status              │  <- Metrics
│  45ms           Healthy             │
├─────────────────────────────────────┤
│         [Open Service →]            │  <- Action Button
└─────────────────────────────────────┘
```

**States:**
- Normal: Transparent background, border
- Hover: Glow effect, lift up 5px
- Offline: Red accent, degraded opacity

### Metric Card
```
┌─────────────────────────────────────┐
│ ��    GPU TEMPERATURE               │  <- Icon + Label
│                                     │
│       72°C                          │  <- Large Value (glowing)
│                                     │
│ ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░               │  <- Progress Bar
└─────────────────────────────────────┘
```

**Progress Bar:**
- Green: 0-74% (Normal)
- Yellow: 75-84% (Warning)
- Red: 85-100% (Critical)
- Animated shimmer effect

### Status Badge
```
┌──────────────┐
│ ● ONLINE     │  <- Pulsing dot + text
└──────────────┘
```

**Variants:**
- ONLINE: Green glow
- DEGRADED: Yellow glow
- OFFLINE: Red glow
- CRITICAL: Red pulsing

### Alert Item
```
┌─────────────────────────────────────┐
│ ⚠ GPU temperature high: 82°C        │  <- Icon + Message
└─────────────────────────────────────┘
```

**Types:**
- ✓ Success (Green)
- ⚠ Warning (Yellow)
- ✗ Danger (Red)

## Visual Effects

### Glassmorphism
```css
background: rgba(15, 23, 42, 0.8);
backdrop-filter: blur(10px);
border: 2px solid rgba(0, 255, 159, 0.3);
```

### Glow Effects
```css
/* Text Glow */
text-shadow: 0 0 10px #00ff9f, 0 0 20px #00ff9f;

/* Box Glow */
box-shadow: 0 0 20px rgba(0, 255, 159, 0.3);

/* Strong Glow (Hover) */
box-shadow: 0 0 40px rgba(0, 255, 159, 0.5);
```

### Animations

#### Pulse (Status Indicator)
```css
@keyframes pulse {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.6; transform: scale(1.2); }
}
```

#### Shimmer (Progress Bar)
```css
@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}
```

#### Glow Pulse (Text)
```css
@keyframes text-glow {
  0%, 100% { text-shadow: 0 0 10px #00ff9f; }
  50% { text-shadow: 0 0 20px #00ff9f, 0 0 40px #00ff9f; }
}
```

#### Slide In (Alerts)
```css
@keyframes slideIn {
  from { opacity: 0; transform: translateX(-20px); }
  to { opacity: 1; transform: translateX(0); }
}
```

#### Twinkle (Stars Background)
```css
@keyframes twinkle {
  0%, 100% { opacity: 0.3; }
  50% { opacity: 0.5; }
}
```

## Interactions

### Hover States
- **Cards:** Lift 5px, add glow, increase opacity
- **Buttons:** Lift 2px, increase glow intensity
- **Metrics:** Brighten values, pulse effect

### Transitions
```css
transition: all 0.3s ease;  /* Default for most elements */
transition: transform 0.5s ease;  /* Smooth transforms */
```

### Active States
- **Buttons:** Pressed down (translateY: 0)
- **Links:** Brightness increase
- **Refresh Icon:** 360° rotation

## Responsive Breakpoints

```css
/* Desktop Large */
@media (min-width: 1600px) {
  /* Max width 1600px */
}

/* Desktop */
@media (min-width: 1200px) {
  /* 3-4 column layouts */
}

/* Tablet */
@media (max-width: 1199px) {
  /* 2 column layouts */
  /* Smaller fonts */
}

/* Mobile */
@media (max-width: 768px) {
  /* Single column */
  /* Stacked header */
  /* Touch-friendly sizes */
}
```

## Accessibility

### Contrast Ratios
- Text on dark: 14:1 (AAA)
- Status badges: 7:1 (AA)
- Interactive elements: High contrast borders

### Focus States
```css
:focus {
  outline: 2px solid #00ff9f;
  outline-offset: 2px;
}
```

### Font Sizes
- Minimum: 14px (0.875rem)
- Body: 16px (1rem)
- Headings: 19px+ (1.2rem+)

## Performance

### GPU Acceleration
```css
transform: translateZ(0);  /* Force GPU rendering */
will-change: transform;     /* Optimize animations */
```

### Loading Strategy
1. Critical CSS inline
2. Fonts preconnect
3. Images lazy load
4. Animations deferred

## Browser Support

### Modern Features Used
- CSS Grid
- Flexbox
- CSS Variables
- Backdrop Filter
- Web Fonts

### Fallbacks
- No backdrop-filter: Solid background
- No CSS Grid: Flexbox fallback
- No custom fonts: System fonts

## Design Inspiration

**Themes:**
- Cyberpunk 2077
- Tron Legacy
- Ghost in the Shell
- Modern sci-fi interfaces
- AI consciousness visualization

**Key Elements:**
- Neon lighting in darkness
- Holographic displays
- Digital consciousness
- Neural networks
- High-tech minimalism

## Implementation Notes

### CSS Architecture
```
styles.css
├── Variables & Reset
├── Base Styles
├── Layout (Container, Grid)
├── Components
│   ├── Header
│   ├── Metrics
│   ├── Services
│   ├── Info Cards
│   └── Footer
├── Utilities
├── Animations
└── Responsive
```

### Performance Metrics
- First Paint: < 1s
- Interactive: < 1.5s
- Total Size: ~40KB (gzipped)
- Lighthouse Score: 95+

### Browser Testing
- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+
- ✅ Mobile browsers

---

**Design crafted for the Brain AI System - Where consciousness meets code** 🧠✨
