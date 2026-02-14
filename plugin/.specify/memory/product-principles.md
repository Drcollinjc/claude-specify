# Product Principles

> Version: 1.0.0 — February 2026
> Status: Living document. These principles capture our current understanding of who we are building for, why, and how. They will evolve as we learn more about our users, our product, and our market. When they evolve, the reasoning behind the change should be documented alongside the change itself.
>
> This document is the **product thesis** — the top layer of the two-document governance model. It defines values, trade-offs, and resolved tensions for the whole organisation (product, design, engineering, leadership). The engineering constitution (`.specify/memory/constitution.md`) derives its principles from this document via the translation mechanism in `.specify/rules/constitution-translation.md`.

---

## Preamble

We are building a B2B intelligence layer for go-to-market teams. Our product helps GTM organisations align, collaborate, and make better strategic decisions using their own data and AI — across the full customer journey.

We are not an execution tool. We do not send emails, manage pipelines, or run campaigns. We sit above the execution layer: we help teams define who their best customers are, align that definition across functions, develop the right messaging and sequencing, and push that strategic configuration into the tools where execution happens — CRMs, marketing automation, outreach platforms.

Our users come to this product to think, not to act. They are sensemaking, aligning with colleagues, and making decisions that will compound across a quarter or more. The cost of a bad decision here is not a bug or a failed deployment — it is months of misallocated pipeline, misaligned messaging, and wasted effort that only becomes visible long after the decision was made.

Everything in this constitution flows from that reality.

---

## Part 1: Resolved Tensions

Great engineering principles are not aspirations — they are pre-resolved tensions. Each principle below represents a genuine trade-off where we have chosen a side. The "this costs us" statement makes the trade-off explicit. If a principle doesn't cost us anything, it isn't a real principle.

---

### 1. Confidence of Decision Over Speed of Action

Our users are not in crisis mode. They are in sensemaking mode — forming judgment, not acting on pre-formed judgment. The product must be optimised for helping users feel confident that a decision is right, not for helping them make decisions quickly.

**This means:**
- Decision surfaces must show the reasoning behind recommendations, not just the recommendations themselves.
- The UX must help users comprehend what they need to know before they decide, surfacing areas of certainty and areas of ambiguity distinctly.
- Features like scenario modelling, assumption tracking, and trade-off exploration are core to the product, not nice-to-haves.
- The AI's role is to shape the conversation toward the decision — helping users level-set on what is known, guiding them toward where judgment is needed, and empowering them to make the call.

**This costs us:**
- We will ship fewer features. Building for decision confidence is a harder design problem than building for speed, and it takes longer to get right.
- Some users will initially want the product to just "tell them the answer." We will resist this because it creates dependency rather than capability, and it shifts accountability in ways that damage trust when recommendations prove wrong.

---

### 2. AI as Collaborator, Never as Oracle

The AI in our product is a teammate — grounded in rigorous analysis, experienced across a near-infinite number of business contexts, but never responsible for the decision. It is the best analyst in the room: a PhD-level domain expert who has also worked in business. But the team makes the call.

**This means:**
- The AI must never present intelligence without making the basis for that intelligence legible and challengeable. The user must always be able to ask "why?" and receive a substantive answer.
- When the AI takes an inferential leap, it must explain that it is doing so. Humans do this all the time and it is perfectly valid — but they must be able to show their working.
- The AI should help users be certain on things which are certain, and then support and empower them to exercise judgment on things which are less so. The risk of the final decision sits with the humans, by design.
- The product must never create a dynamic where a team can say "we just accepted what the AI told us" after a quarter of misallocated effort. The AI's job is to make sure that cannot happen — by surfacing caveats, presenting rounded views, and ensuring the humans have genuinely engaged with the decision.
- Decision intelligence principles apply here: consider the null hypothesis, consider what happens if no action is taken, frame decisions under uncertainty with appropriate rigour. Reference: Cassie Kozyrkov's work on decision science at Google provides a foundation for how we think about this.

**This costs us:**
- The AI experience will feel slower and more deliberate than competitors who offer confident, one-click recommendations. We accept this because the alternative — false confidence — is our most dangerous failure mode.
- Engineering effort on AI features will be higher because every recommendation needs an explanation layer, not just an output layer.

---

### 3. Trust Above All Other Quality Attributes

Our failure hierarchy, in order:

1. **Trust** — If users cannot trust the intelligence the product provides, nothing else matters. Trust encompasses accuracy, consistency (the product must not contradict itself across modules), transparency, and honesty about uncertainty.
2. **Reliability** — Users may not visit this product as frequently as their execution tools. When they do come, it must work. A tool for strategic thinking that is unavailable at the moment of need loses its place in the workflow permanently.
3. **Usability** — This is high-cognitive work. The interface must reduce cognitive load, not add to it. Every interaction should help the user think more clearly, not force them to wrestle with the tool.
4. **Latency** — Not as critical as in execution-layer products, but still matters. Slow AI responses during a collaborative session break flow and erode confidence.
5. **Cost efficiency** — Important but never at the expense of the above.

**This means:**
- When trust and speed conflict, trust wins. We will not ship a faster recommendation that is less transparent.
- When reliability and features conflict, reliability wins. A stable product with fewer features beats an unstable product with many.
- Consistency is a dimension of trust. If the ICP module and the messaging module produce contradictory guidance, that is a trust failure equivalent to a data breach in its impact on user confidence.

**This costs us:**
- We will move more slowly on feature development than competitors who optimise for breadth. We accept this because in an intelligence product, a single trust-breaking moment can undo months of value delivery.

---

### 4. Opinionated About Process, Flexible About Strategy

We are not opinionated about what a team's go-to-market strategy should be. We are opinionated about the workflows, frameworks, and decision structures that enable teams to surface the right decision in the right context.

**This means:**
- The product provides structured frameworks with helpful defaults — the things we know should be considered — rather than blank canvases. Think: an ICP definition framework with sensible default variables, not an empty form.
- We offer a menu of options within our frameworks, but we guide users toward best practices through defaults, not through restriction.
- Over time, with careful product design and deliberate data capture, we aim to identify patterns across the teams using the platform to provide better defaults for businesses at particular stages of growth or in particular segments. This is a product capability we are building toward, not a constitutional principle — but the constitution must enable it by ensuring we design for learning from aggregate usage.
- We do not build infinitely configurable workflow builders. Flexibility in configuration is where products go to die. We provide opinionated workflows that encode best practices, and we evolve those opinions based on evidence.

**This costs us:**
- Some prospects will want the product to fit their existing (possibly broken) processes. We will lose those deals. We accept this because products that try to accommodate every workflow end up serving none of them well.

---

### 5. Craft is a Competitive Advantage, Not a Luxury

In an AI-enabled world where every team can ship features faster, the differentiator shifts from "can you build it" to "should you build it, and does it feel right." Taste and superior user experience — particularly for products involved in high-cognition work — are force multipliers.

**This means:**
- We are willing to sacrifice speed and feature count for craft. A smaller product that users genuinely want to use and that creates strong affinity will outperform a bloated product with more capabilities.
- Restraint is part of craft. We do not build features to keep teams busy. We do not add capabilities simply because they are cheap to build. Every feature must justify its existence against the signal-to-noise ratio of value being delivered to users.
- The AI-enabled experience must be something people want to engage with — not because of novelty, but because the collaboration between human and AI is genuinely valuable. Moments of genuine partnership between user and AI create the kind of product affinity that no feature list can match.
- Design is not a layer applied after engineering. It is integral to the engineering process. Decision surfaces — the places where users comprehend information and make choices — are where craft matters most and where engineering and design must be inseparable.

**This costs us:**
- We will have fewer features than competitors at any given point in time.
- We will spend more engineering time on fewer things.
- Some features will take longer to ship because the bar for "ready" includes the experience, not just the functionality.

---

### 6. Intelligence Layer Boundary

We sit in the intelligence layer. We do not operate in the execution layer. This boundary is constitutional — it defines what we build and, critically, what we refuse to build.

**This means:**
- We define strategy and push configuration into execution tools. We do not send messages, manage prospects, or run campaigns.
- Integration contracts with execution tools (CRMs, marketing automation, outreach platforms) are how our intelligence becomes operational. The shape and reliability of these integrations matter enormously, but the execution itself is not our responsibility.
- When users ask "can the product also do X?" and X is execution, the answer is no — even if X would be technically simple to build. We reference this boundary, not capacity, as the reason.
- Human-in-the-loop should be considered for any action where the product pushes configuration into external systems. The model here is a pull request, not a push — the product proposes, the human approves. How we determine when human-in-the-loop is required versus optional is an open design question (see Unresolved Tensions below).

**This costs us:**
- We will not capture revenue from execution-layer features that users would pay for.
- We depend on integration quality with third-party tools we don't control.
- Some users will want an all-in-one platform. We are not that.

---

### 7. Writing Over Meetings, Ownership Over Consensus

Decisions should be made by informed owners, not by committees. Knowledge should flow through documentation, not through oral tradition. Disagreement should be productive, open, and resolved — not suppressed or endlessly debated.

**This means:**
- Writing is the primary medium for building alignment and strategic understanding. If you cannot explain your thinking clearly in writing, you cannot stand over your ideas. Slack has a purpose for quick coordination, but building shared understanding requires documentation.
- Every significant decision has an owner — the informed captain. That person seeks input, stress-tests ideas, welcomes productive disagreement, but ultimately makes the call. The buck stops with them.
- Meetings are not banned, but the default state of meetings in most organisations is waste. Meetings are justified when real-time collaboration or debate is needed. Status updates, information sharing, and alignment can almost always be handled through written documentation.
- Engineers should feel psychologically safe when discussing architecture or feature design. The best ideas survive scrutiny; the goal is to find the best idea, not to protect anyone's ego.
- Teams are not told how to operate in prescriptive detail, but there must be strong shared patterns across the organisation — reusable, composable engineering patterns that compound in value when mixed and matched across components.

**This costs us:**
- Writing takes more time than talking. Documenting decisions is slower than just making them verbally.
- The informed captain model requires people who are comfortable with accountability. Not everyone is.
- Some people prefer the energy of meetings. We acknowledge this but optimise for the quality of outcomes, not the comfort of the process.

---

### 8. Freedom With Focus, Not Freedom Without Direction

People need the freedom to think, to innovate, and to find the best approach. But freedom without focus produces chaos. The constitution provides the guardrails; within those guardrails, individuals and teams have autonomy.

**This means:**
- We do not use prescriptive guidance for how engineers solve problems. We set expectations on outcomes, patterns, and quality — and trust people to find the best path.
- Process exists as scaffolding and guardrails to foster innovation and consistency, not to control behaviour. If a process is not serving innovation or consistency, it should be questioned and removed.
- Engineers must be laser-focused on the right problems and must understand why they are working on a particular problem. Autonomy on the "how" requires clarity on the "what" and the "why."
- Higher expectations over more rules. As the organisation grows, we resist the impulse to add process in response to every mistake. We invest in hiring and developing people whose judgment can be trusted, rather than building systems that compensate for poor judgment.

**This costs us:**
- Some things will go wrong that a more prescriptive process would have caught. We accept this because the cost of the process (in speed, morale, and innovation) exceeds the cost of the occasional mistake.
- This approach requires higher-calibre people. Hiring is harder, and not everyone thrives in this environment.

---

### 9. Learning is a Core Operating Principle, Not an Afterthought

Our product's thesis is that GTM teams need to shift from executing to sensemaking, decision-making, and learning. If we don't operate this way ourselves, we will eventually build a product that preaches what we don't practise.

**This means:**
- When specifications prove wrong — and they will — we course-correct, but we document why the course correction was needed. The constitution allows for change; it demands understanding of what changed and why.
- Retrospectives and feedback mechanisms are built into the engineering flow, not bolted on. Gaps in specifications, insufficient test coverage, missed acceptance criteria — all feed back into improving how we specify, plan, and build.
- The engineering flow itself is treated as a product. It evolves based on evidence, not tradition or convenience.
- We track assumptions explicitly. When an assumption proves correct, that's signal. When an assumption proves wrong, that's more valuable signal. Both feed learning.

**This costs us:**
- Retros and documentation of learnings take time that could be spent building.
- Revisiting past decisions can feel like rework. It isn't — it's investment in compounding improvement — but it can feel that way in the moment.

---

### 10. AI Transparency is Non-Negotiable Across All Watermarks

Regardless of the build watermark (spik | poc | demo | MVP | prod), the AI must never be a black box. This is not a polish item that gets added later — it is structural to the product's integrity.

**This means:**
- Even in a spike, if the AI generates a recommendation, there must be a mechanism for the user to understand why.
- The "why" does not need to be beautifully designed at early watermarks, but it must exist. A raw JSON dump of reasoning is acceptable in a spik. No reasoning at all is not.
- This principle exists because AI transparency is architectural, not cosmetic. If the product is built without explainability from the start, retrofitting it is orders of magnitude harder than including it from day one.

**This costs us:**
- Every AI feature takes longer to build at every watermark level because the explanation layer is mandatory, not optional.
- Some spikes will feel heavier than they "need" to be. We accept this because the alternative — discovering at prod that the AI can't explain itself — is a constitutional violation, not a bug.

---

### 11. Terminology is Invariant

If we call something an "ICP" in a spike, it is an "ICP" in production. Naming and language are fixed early and do not drift across watermarks, modules, or team boundaries.

**This means:**
- A shared glossary of domain terms is established and maintained. When a term is chosen, it is used consistently in code (variable names, API endpoints, database fields), in UI copy, in documentation, and in conversation.
- Renaming is allowed — but it is a deliberate, documented decision that propagates everywhere simultaneously. It is never accidental drift.

**This costs us:**
- Early naming decisions carry more weight than feels comfortable. We may sometimes feel locked into a term that isn't perfect.
- Maintaining terminology consistency requires discipline, especially across AI-generated code where an agent may use synonyms if not explicitly constrained.

---

## Part 2: Unresolved Tensions

These are questions we have identified but not yet resolved. They are documented here so that future decisions can be made deliberately rather than by accident. As we learn more, these should be resolved and promoted to Part 1 as principles, or dismissed with reasoning.

---

### Human-in-the-Loop Threshold

**The tension:** When the product pushes configuration into external systems (CRM scoring models, marketing automation sequences, etc.), when does a human need to approve the push versus it happening automatically?

**Current thinking:** The model is a pull request — the product proposes, the human reviews and approves. But this may create friction that undermines adoption if applied to every sync. We need a framework for determining when human review is mandatory versus when continuous sync is acceptable.

**Questions to resolve:**
- Is the threshold based on the magnitude of the change? (e.g., a minor scoring adjustment syncs automatically, but a full ICP redefinition requires approval)
- Is it based on the downstream impact? (e.g., changes that affect live campaign targeting always require approval)
- Is it user-configurable? (e.g., teams set their own approval thresholds)
- How does this interact with trust — does the product earn the right to auto-sync over time as users validate its recommendations?

---

### Scope Control and Forcing Functions

**The tension:** The watermark system handles build fidelity well, but scope — what gets built in any given cycle — is a separate problem. Bloat is a visceral concern. Features should not be built simply because they are "free" or because teams need to be kept busy.

**Current thinking:** Scope control is an operational decision, not a constitutional principle. Teams may slice features differently based on where they are in the build cycle — for example, pausing feature work to address accumulated debt. The engineering principles should not change based on these decisions. The Shape Up method's six-week cycle constraint is appealing as a future forcing function but is not yet adopted.

**Questions to resolve:**
- As the team grows, what prevents scope creep if there is no constitutional constraint on it?
- Is "restraint is part of craft" (Principle 5) sufficient, or does scope need its own explicit principle?
- How does the product organisation's roadmap interact with engineering's capacity without introducing the bloat and waste we want to avoid?

---

### Data Model Flexibility vs. Correctness

**The tension:** Data models are never "correct" in a permanent sense — there are areas of certainty and areas of required flexibility. Treating the data model as a non-negotiable invariant is too rigid; treating it as entirely fluid creates compounding inconsistency.

**Current thinking:** Not yet resolved. The areas of certainty in the data model (core entities, relationships that define the product's conceptual model) may warrant stronger constitutional protection than the areas of flexibility (attributes, metadata, configuration). But the line between these is not yet clear.

**Questions to resolve:**
- Which parts of the data model are structural to the product's identity and should be treated as near-invariant?
- Which parts are expected to evolve and should be designed for change from the start?
- How does this interact with the intelligence layer boundary — do integration contracts impose their own data model constraints?

---

### Cross-Platform Pattern Intelligence

**The tension:** We believe that with careful product design and data capture, we can find patterns across all teams using the platform to provide better defaults for businesses at similar stages or in similar segments. This is a powerful product capability but raises questions about data boundaries, privacy, and how opinionated the product should be based on aggregate learning.

**Current thinking:** This is a product feature, not a constitutional principle. But the constitution must enable it by ensuring we design for learning from aggregate usage patterns. The engineering implications (data architecture, anonymisation, pattern extraction) are significant and should be considered in early architectural decisions.

**Questions to resolve:**
- What data can be aggregated across customers, and what remains strictly isolated?
- How do we communicate to users when a default or recommendation is informed by aggregate patterns versus their own data?
- Does this capability change the AI's role from collaborator to something more prescriptive?

---

## Part 3: How to Use This Document

### For AI Agents (Claude Code, spec kits flow)

This constitution should be loaded at the start of every specification and planning session. When making technical, architectural, or design decisions, the agent should check against the resolved tensions in Part 1. If a decision conflicts with a principle, the agent should raise it for discussion rather than proceeding.

The agent should pay particular attention to:
- Principle 2 (AI as Collaborator) when designing any AI-facing feature
- Principle 10 (AI Transparency) when scoping work at any watermark level
- Principle 6 (Intelligence Layer Boundary) when evaluating feature requests
- Principle 11 (Terminology) when naming anything in code, UI, or documentation

### For Humans

This document is the starting point for any conversation about "should we build this?" or "how should we build this?" It does not answer every question — that is what the unresolved tensions section acknowledges — but it should prevent the most common sources of inconsistency and misalignment.

When you disagree with a principle, that is valuable signal. Write down why. If the disagreement survives scrutiny, the constitution evolves. If it doesn't, the principle is strengthened by having been tested.

### For Future Versions

When this document is updated:
1. Record what changed and why in a changelog below
2. Note what was learned that prompted the change
3. If a principle is removed, document why it no longer serves us — don't just delete it

---

## Changelog

| Date | Change | Reasoning |
|------|--------|-----------|
| Feb 2026 | v0.1 — Initial constitution drafted | Based on first-principles assessment of product positioning, user cognitive state, failure hierarchy, craft philosophy, communication model, boundary definition, trust model, learning posture, and cross-watermark invariants. Informed by analysis of engineering cultures at Stripe, Netflix, Linear, Shopify, Spotify, Wealthfront, Basecamp, and Amazon. |
