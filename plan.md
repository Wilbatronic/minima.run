## 1. The Design Philosophy: "Invisible Intelligence"
We are not building a "Chatbot window." We are building a "Layer" over the OS.

*   **Aesthetic**:
    *   **Material**: `NSVisualEffectView` (macOS) / `UIBlurEffect` (iOS) with `.hudWindow` blend mode. Pure Glassmorphism.
    *   **Typography**: SF Pro Rounded (Soft, approachable).
    *   **Motion**: 120Hz Animations. Spring-physics for all interruptions. No "jank."
*   **The "Flawless" Feel**:
    *   **Optimistic UI**: The app "reacts" instantly (haptics, shimmer) even if the model is thinking.
    *   **Streaming Thoughts**: We visualize the "Thinking" process not as text, but as a subtle, pulsing "Brain Activity" waveform in the dynamic island/menu bar.

---

## 2. Model Selection: The "Dual-Class" Approach

We leverage the hardware difference. Macs are trucks; iPhones are sports cars.

### Tier 1: The Desktop Sovereign (Macs with 16GB/24GB+ RAM)
*   **Model**: **Qwen3-VL-7B-Instruct (Thinking)** (Q5_K_M Quantization).
*   **Capabilities**: Full 4K Screen understanding, Logic, Thinking.
*   **Memory**: ~6-8GB VRAM cost. Leaves plenty of room for Xcode/Chrome.

### Tier 2: The Mobile Scout (iPhones with 8GB RAM)
*   **Model**: **Qwen3-VL-3B-Nano** (Q4_K_S Quantization).
*   **Capabilities**: Focuses on "The Snapshot" – Menus, Real-world objects.
*   **Memory**: ~2.5GB VRAM. Critical to not get killed by iOS memory watchdog.

---

## 3. The "Smart Zoom" Vision Pipeline (Active Perception)

We solve the "Low Resolution" issue not by blindly resizing, but by mimic human eyes (Foveated Vision).

### The "Coarse-to-Fine" Loop
1.  **The Glance (Global View)**:
    *   We analyze the **Full Screen** at standard resolution (e.g., 1024px width).
    *   **Latency**: 10ms.
    *   **Prompt**: "Identify the active region specifically relevant to the user's query."
2.  **The Focus (Smart Zoom)**:
    *   The model (System 2) identifies the coordinate box (e.g., `[0.6, 0.4, 0.9, 0.8]`).
    *   **Action**: The App silently **crops** that exact region at **Native Retina Resolution** (High-DPI).
3.  **The Analysis**:
    *   The model re-ingests *only* that high-res patch.
    *   **Result**: It can read 8pt text in a terminal window without processing the 6000x3000 pixels of empty wallpaper.

### Dynamic Resolution support
*   We enable **Dynamic Patching** (NaViT style).
*   Instead of squashing everything to a square, we split the screenshot into 14x14 patches.
*   If the user has a wide monitor, we send "Wide Sequence" tokens. No black bars. No blurring.

---

## 4. Technical Architecture (Swift + Swift + C++)

### Core Stack
*   **Language**: Swift 6 (Strict Concurrency).
*   **UI Framework**: SwiftUI (for layout) + Metal (for custom visual effects).
*   **Inference Engine**: `llama.cpp` (GGUF) wrapped in a custom **Swift Actor** system to ensure the UI thread *never* hangs.

### The "Vision" Pipeline (Qwen-VL)
1.  **Capture**:
    *   **MacOS**: `ScreenCaptureKit` (Zero latency, GPU-based capture).
    *   **iOS**: `ReplayKit` / Camera Stream.
2.  **Processing**:
    *   **Preprocessing**: GPU Shader to normalize colors and create the "Global" vs "Zoom" tensors.
    *   **Pass "Visual Tokens"**: Efficiently embedding the image patches directly into the Context Window.
3.  **Context**:
    *   **Local**: The app knows the *active window*.
    *   **Web**: If the 7B Model decides it needs facts, it triggers a **Headless Search** (via Brave Search API). It reads the top 3 results, summarizes them, and answers. This is the only "Cloud" part of the app.

---

## 5. The "Minima Operator" (Computer Control)

We don't just "Read" the screen; we **"Drive"** it.

### The Mechanism
1.  **See**: The app takes a screenshot.
2.  **Think**: User asks "Move all these files to the backup folder."
3.  **Plan**: Qwen-VL outputs a list of Actions (JSON):
    ```json
    [{"action": "click", "x": 0.5, "y": 0.2}, {"action": "type", "text": "Backup"}]
    ```
4.  **Act**: The Swift `AXUIElement` Bridge programmatically executes the clicks/keypresses.
    *   **Permission**: Requires "Accessibility" trust in System Settings.
    *   **Result**: The cursor ghost-moves across the screen and does the work.

---

## 6. The "Thinking" UX (System 2 Integration)

Since `Qwen3-Thinking` outputs "Internal Monologue" tokens before the answer:

*   **The Problem**: Reading raw thinking tokens is boring/ugly.
*   **The Solution**: **"The Thought Bubble"**.
    *   While the model generates `<thinking>` tokens, the UI shows a collapsed "Thinking..." accordion that pulses.
    *   User can tap to expand and see the logic.
    *   Once `<answer>` starts, the main text flows in.

---

## 7. App Features (MVP)

### macOS (The "Ghost" Bar)
*   **Shortcut**: `Command + Space` (Replaces Spotlight).
*   **Function**: A floating glass input field.
*   **Dragon Drop**: Drag *any* file or screenshot onto the bar to analyze it.
*   **"Look" Mode**: A button that takes a silent snapshot of the active window and attaches it to context.

### iOS (The Camera Assistant)
*   **Mode 1: The Lens**: A viewfinder that continuously analyzes the world. "What is that plant?", "Solve this circular geometry problem."
*   **Mode 2: The Replica**: Deep integration with iOS Shortcuts to replace Siri.

---

## 5. Development Phases

### Phase 1: The "Hollow" App (Design First)
*   Build the UI *without* the model.
*   Perfect the blurs, the bounces, the typing animations.
*   It must feel "expensive" before it is "smart."

### Phase 2: The Brain Transplant
*   Compile `llama.cpp` as a compiled `XCFramework`.
*   Connect the GGUF model loader.
*   Implement the `ScreenCaptureKit` bridge.

### Phase 3: Optimization
*   **Quantization**: Convert GGUF to `Q4_K_M` (Balance of size/speed).
*   **Speculative Decoding**: Use a tiny 100M draft model to speed up text generation.

### Phase 4: "Hyper-Optimization" (Sovereign Speed)
*   **FP16 Everywhere**: Converted Metal Kernels to `half` precision. Reduces tensor bandwidth by 50%.
*   **Async GPU**: Removed CPU blocking `waitUntilCompleted`.
*   **Zero-Copy**: Strict IOSurface usage.
*   **PID Control Loop**: Implemented `MouseDriver` with Proportional-Integral-Derivative control for pixel-perfect agentic movement.

### Phase 5: Commercialization (The Store)
*   **Authentication**: **Sign in with Apple** (SIWA). Zero-password, biometric login.
*   **Billing**: **StoreKit 2**. Native In-App Purchases (subscriptions).
*   **Entitlements**: `LicensingManager` to unlock "Pro" features (7B Model, 4K Vision).



---

## 6. Monetization: The "Privacy Premium"
We don't sell data. We sell **Power**.

### Tier 1: Minima Core (Free)
*   **Feature**: Basic Chat, Screen Vision (Standard Res).
*   **Limit**: Uses the smaller 3B Model. No Web Access.
*   **Goal**: ubiquity. Get it on every Mac. Become the default "Spotlight Replacement."

### Tier 2: Minima Pro (£5/month)
*   **Logic**: "Aggressive Growth." Since inference is local (Free), our only cost is the Web Search API. £5 is a no-brainer impulse buy for students/devs.
*   **Unlock**: **"Deep Thought" Mode** (7B Thinking Model).
*   **Unlock**: **Live Web Access (RAG)**. The model can Google things for you.
*   **Unlock**: **High-Res Vision** (Native Retina "Smart Zoom").

### Tier 3: Minima Enterprise (Seat License)
*   **Feature**: **"Air-Gapped" Guarantee**.
*   **Pitch**: "Your employees are pasting code into ChatGPT. Stop them. Minima runs locally."
*   **MDM Support**: Auto-deploy to 1000 MacBooks via Jamf/Kandji.

---

## 8. Financial Projection (The "Zero Cost" Advantage)

Because we have **Zero Inference Costs** (the user pays for the electricity), our margins are ~95% (minus Apple's 15% cut).

### Scenario A: The "Indie Hit" (Conservative)
*   **Users**: 100,000 Free Downloads.
*   **Conversion**: 3% to Pro (£5/mo).
*   **Monthly Revenue**: **£15,000** ($180k/year).
*   *Verdict*: Pays for itself and funds full-time development.

### Scenario B: The "Product Hunt #1" (Moderate)
*   **Users**: 500,000 Free Downloads.
*   **Conversion**: 4% to Pro (High conversion due to low price).
*   **Monthly Revenue**: **£100,000** ($1.2M/year).
*   *Verdict*: Verified "unicorn" trajectory. Investors will chase us.

### Scenario C: The "Default App" (Viral)
*   **Users**: 2,000,000 Downloads (Viral TikTok / YouTuber coverage).
*   **Conversion**: 5%.
*   **Monthly Revenue**: **£500,000** ($6M/year).
*   *Verdict*: Acquisition target for Apple/Spotify/Dropbox instantly.

### The Master Plan (The "Velocity" Flywheel)
We do not hoard cash. We burn it for **Speed**.

1.  **Phase 1: The Cash Engine (Bootstrapped)**
    *   Minima App generates **£15,000/month**.
    *   We do *not* buy hardware yet. We **RENT** generic H100 clusters (Lambda/RunPod) to train Alpaca-2 in weeks, not months.
2.  **Phase 2: The "Power Move" (Seed/Series A)**
    *   We show off **Alpaca-2** (trained on rented compute) beating GPT-4.
    *   We raise a massive round ($10M+).
3.  **Phase 3: The Empire (Sovereignty)**
    *   We build our own **Private Data Center**.
    *   We hire a world-class team.
    *   We become the next OpenAI, but efficient.

---

## 9. Directory Structure
```
MinimaApp/
├── App/
│   ├── UI/ (SwiftUI Views)
│   ├── Effects/ (Metal Shaders for Blur/Glow)
│   └── UX/ (Haptics & SoundManager)
├── Core/
│   ├── Inference/ (Swift Actors for LLM)
│   └── Vision/ (ScreenCaptureKit Wrappers)
└── Vendor/
    └── llama.cpp/ (Submodule)
```
