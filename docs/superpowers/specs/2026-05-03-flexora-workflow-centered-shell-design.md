# Flexora Workflow-Centered Shell Design

**Date:** 2026-05-03  
**Platform:** macOS  
**Stack:** Swift, SwiftUI, AVFoundation, AppKit interop where needed

## Summary

Flexora should no longer present modules as the primary user-facing entry point. The product should become workflow-centered: modules provide capabilities, workflows are the runnable objects, the workshop builds and edits workflows, and the home page is where users launch saved workflows to complete tasks.

The first module remains video frame extraction for turning dynamic wallpapers into static wallpapers. In the new shell, that module automatically contributes a default single-module workflow, while future multi-module workflows will be assembled in the workshop through a node graph.

## Product Direction

- Home should show workflows, not raw modules.
- Workshop should be the place where users compose and repair workflows.
- Modules should be managed as capability cards that can be enabled or disabled.
- Disabled modules must not delete dependent workflows.
- Single-module workflows should work naturally without forcing the user to understand module internals.
- The app should preserve a path to future multi-module collaboration without requiring a full execution engine in V1.

## V1 Scope

### In Scope

- Replace the current module-chooser-centric shell with a workflow-centered shell.
- Add fixed sidebar navigation for `Home`, `Workshop`, and `Modules`.
- Introduce workflow records as first-class app state.
- Auto-generate a default workflow for every enabled module.
- Show both default and custom workflows on the home page.
- Support user-defined multi-select tags for workflows.
- Support workflow grouping and filtering by source and tags.
- Keep unavailable workflows visible as disabled gray cards.
- Allow unavailable workflows to open in the workshop for repair.
- Change the video module preview to a larger immersive presentation.
- Remove the visible `Close Preview` button and rely on keyboard dismissal.
- Fix export flow so it uses a more explicit, reliable save target workflow.

### Out of Scope

- Full low-code runtime execution across multiple modules.
- Branch execution, merge execution, or background workflow scheduling.
- Cloud sync, sharing, or downloading modules from a marketplace.
- Persisting a production-grade workflow versioning system.
- A full node-type system with typed port validation beyond basic capability checks.

## Core Product Objects

### Module

A module is an install-time capability provider. It is not a launch surface on the home page.

Each module exposes:

- `id`
- `name`
- `summary`
- `capabilities`
- `isEnabled`
- lifecycle hooks such as `load()` and `unload()`
- a workspace factory for rendering the module’s task UI
- future-facing metadata for workflow nodes

Examples:

- Video Frame Extraction
- PDF Conversion
- Audio Extraction

### Workflow

A workflow is the primary runnable object in the product. Every home card maps to a workflow.

Workflow sources:

- `default`: auto-generated from a single enabled module
- `custom`: created or edited by the user in the workshop

Workflows remain editable regardless of source. A default workflow may be edited directly and stays the same workflow after edits.

### Workflow Node

A workflow node references a module capability inside a node graph. Nodes are not standalone runnable entities outside the containing workflow.

Each node should hold:

- stable identity
- referenced `moduleID`
- title
- canvas position
- lightweight input/output port metadata
- availability derived from the referenced module

### Tag

Tags are user-defined classification fields for workflows. A workflow can have multiple tags.

Tags are distinct from source:

- `source` is system-owned and indicates `default` or `custom`
- `tags` are user-owned and indicate user classification such as `Wallpaper`, `Batch`, or `Common`

## Information Architecture

### Sidebar Navigation

The main window should have a fixed sidebar with three top-level destinations:

- `Home`
- `Workshop`
- `Modules`

This sidebar should be stable and always visible. It replaces the current module chooser model.

### Home

Home is the primary product surface. Users come here to launch work they have already prepared.

Home responsibilities:

- display all workflows as cards
- visually distinguish `default` and `custom` workflows
- support filtering by source and tags
- support grouped presentation by tags
- preserve unavailable workflows as gray disabled cards
- allow opening a workflow task page
- allow opening the workflow editor for repair

Home must not show modules as direct launch entries.

### Workshop

Workshop is the workflow editor. It is where users assemble, inspect, repair, and save node-graph workflows.

Workshop responsibilities:

- create new custom workflows
- edit default workflows directly
- show available modules as node templates
- show unavailable nodes clearly when referenced modules are disabled
- edit workflow name, tags, and description
- persist the node graph structure

### Modules

Modules is a management page, not a runtime page.

Modules responsibilities:

- show each module as a card
- expose an enable/disable toggle at the card’s top-right corner
- show module name, summary, and capability hints
- explain that enabling a module makes related workflows available
- avoid direct execution from this page

### Task Page

A task page is opened from a workflow card on Home. It is the execution surface for that workflow.

Task page responsibilities:

- show workflow metadata such as name, source, tags, and state
- host the actual work UI
- load a single-module workflow into the module’s existing workspace
- block execution for unavailable workflows
- provide a path to edit unavailable workflows in the workshop

## Routing Model

The app route model should move from module-first routing to workflow-first routing.

Recommended route set:

- `home`
- `workshop`
- `modules`
- `task(workflowID)`
- `workflowEditor(workflowID)`

The current `workspace(moduleID)` route should no longer be the primary public route. Module workspaces should instead be hosted from `task(workflowID)` when the selected workflow is single-module.

## Workflow State Rules

### Default Workflow Generation

- Every enabled module must have exactly one default workflow.
- If a default workflow already exists for a module, enabling that module should reuse it rather than creating another.
- Default workflows are editable in place.

### Custom Workflow Creation

- Users can create custom workflows in Workshop.
- Custom workflows may reference one or more modules through nodes.
- Custom workflows appear on Home once saved.

### Module Disable Behavior

- Disabling a module must not delete dependent workflows.
- Dependent workflows remain on Home in a gray unavailable state.
- Unavailable workflows cannot be run from Home or the task page.
- Unavailable workflows can still be opened in Workshop for repair.
- Workshop must visibly identify which nodes are unavailable.

### Availability Computation

Workflow availability should be derived, not manually maintained.

Suggested states:

- `available`
- `unavailable`

For V1, a workflow is available only when all referenced modules are enabled. More nuanced partial states can be added later if needed.

## Home Page Interaction Design

### Filter And Group Model

Home should support a mixed browsing model:

- top-level filter chips for `All`, `Default`, `Custom`, and all user tags
- grouped sections in the content area based on tags

This gives the user both quick filtering and a structured library view.

### Card Contents

Each workflow card should show:

- workflow name
- source badge: `Default` or `Custom`
- one or more user tags
- short description
- state badge: `Ready` or `Unavailable`
- primary action
- secondary action

### Card Actions

For available workflows:

- primary action: `Open`
- secondary action: `Edit`

For unavailable workflows:

- primary action disabled
- secondary action: `Edit`
- explicit missing-module notice, ideally naming affected modules

### Gray Unavailable Presentation

Unavailable cards should remain readable but clearly disabled:

- reduced contrast
- disabled primary action
- unavailable badge
- missing-module text

The goal is to preserve user context rather than hiding work.

## Workshop Interaction Design

V1 Workshop should be a node-flow editor skeleton, not a complete automation platform.

Recommended layout:

- left panel: module palette
- center: node canvas
- right panel: workflow and node inspector
- top toolbar: save, validate, return to Home

### Node Rules

- each node references one module
- disabled modules should render their nodes as unavailable
- unavailable nodes should show which module is missing
- users should still be able to move, inspect, and replace unavailable nodes

### Workflow Metadata Editing

The inspector should allow editing:

- workflow name
- description
- tag assignment

### Default Workflow Editing

Default workflows are editable directly. There is no separate immutable system template in V1.

## Modules Page Design

The Modules page should present modules as cards rather than a settings-only list.

Each card should include:

- module name
- short summary
- capability hints
- enabled toggle in the top-right corner

Enabling and disabling must update workflow availability immediately across the app.

## Task Page Design

### Single-Module Workflows

Single-module workflows should reuse the existing module workspace. For V1, the video frame extraction workflow should open the current video module UI inside the task page container.

### Multi-Module Workflows

V1 should not implement full multi-module execution. Instead, the task page for a custom multi-module workflow should:

- show workflow metadata
- show the node graph summary or structure
- expose an execution summary surface reserved for later orchestration work
- block run if required modules are unavailable

This keeps the shell honest without pretending that a full orchestration engine exists yet.

## Video Frame Extraction Changes Required By This Design

### Export Flow

The current export failure demonstrates that the export path handling is not reliable enough.

V1 should move to a more explicit save flow:

- choose a concrete export location with clear write intent
- present format-aware file naming
- surface permission or encoding failure in direct user language

For multi-selection export, the implementation may still use a destination directory, but it should do so with an explicit and validated write strategy rather than a weak optimistic write attempt.

### Preview Experience

The still preview should become immersive:

- significantly larger image presentation
- minimal chrome
- no visible `Close Preview` control
- no oversized white framing
- keyboard-driven dismissal with `Space`
- optional `Escape` dismissal if easy to support

The preview should feel like a viewer, not a card floating inside another card.

## Data Model Proposal

### `ModuleRecord`

Represents module identity and enablement state.

Suggested fields:

- `id`
- `name`
- `summary`
- `capabilities`
- `isEnabled`

### `WorkflowRecord`

Represents a runnable workflow visible on Home.

Suggested fields:

- `id`
- `name`
- `description`
- `source`
- `entryModuleID`
- `nodeGraph`
- `tagIDs`
- `createdAt`
- `updatedAt`

### `WorkflowNode`

Represents one module-backed node in a workflow graph.

Suggested fields:

- `id`
- `moduleID`
- `title`
- `position`
- `inputPorts`
- `outputPorts`

### `TagRecord`

Represents a user-defined tag.

Suggested fields:

- `id`
- `name`
- `color` or style token if needed later

### `WorkflowAvailability`

Derived state based on whether all referenced modules are enabled.

Suggested fields:

- `workflowID`
- `isAvailable`
- `missingModuleIDs`

## Runtime Responsibilities

### Module Runtime

The existing module runtime should remain responsible for:

- registering modules
- enabling and disabling modules
- loading and unloading modules
- providing module descriptors and module workspaces

It should stop acting as the public navigation authority for the app.

### Workflow Store

A new workflow-focused store should be introduced to manage:

- default workflow generation
- custom workflow persistence
- tag creation and assignment
- workflow lookup by route
- availability derivation
- Home grouping and filtering queries

### App Model

The app model should become workflow-centered:

- route tracks workflow destinations
- active task tracks `workflowID`
- module enablement changes recompute workflow availability
- Home, Workshop, Modules, and Task page all read from shared workflow-aware state

## Error Handling

### Unavailable Modules

- unavailable workflows remain visible
- unavailable nodes remain visible
- repair path should always be obvious

### Export Failures

- permission failures should identify the target path problem
- encoding failures should identify the selected format problem
- failures should not silently record a completed export

### Preview Failures

- if no image is available, the preview should show a clear empty state rather than partial chrome

## Testing Expectations

Implementation should cover at least:

- default workflow generation when modules are enabled
- no duplicate default workflow generation
- workflow availability updates when modules are disabled
- unavailable workflows remain visible
- tag filtering and grouping logic
- task route resolution by `workflowID`
- video export path handling
- preview presentation state transitions

## Implementation Boundaries

V1 should deliberately stop short of:

- executing arbitrary node graphs across modules
- complex type-checking between workflow ports
- async orchestration across multiple modules
- background queues for workflow jobs

The architecture should leave room for those features later, but the product should not fake them now.

## Success Criteria

This design is successful when:

- users launch workflows from Home rather than modules directly
- every enabled module contributes a default workflow automatically
- custom workflows can be created in Workshop and appear on Home
- disabled modules visibly invalidate dependent workflows without deleting them
- the Modules page becomes a clear capability-management surface
- the video module preview feels immersive and keyboard-driven
- export failures become explicit and recoverable
