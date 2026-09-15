# GroundTruth

**Author:** Aryan Cyrus  
**Student ID:** 33114242  
**Date:** 16/08/2026

---

# Overview

GroundTruth is an iOS application designed to help Victorian property owners, contractors, and small businesses navigate the planning, building, and construction process.

Construction projects often require compliance with planning schemes, building regulations, local laws, permits, and various other requirements. Much of this information is difficult to understand, highly technical, and spread across multiple sources.

GroundTruth aims to simplify this process by providing:

- Easy-to-understand guidance on planning and building requirements
- Property-specific information based on location
- References to relevant legislation, regulations, and documentation
- Project roadmaps and checklists
- AI-assisted project consultation
- Approximate project cost estimates

The goal is to help users move from project idea to project completion with greater confidence and clarity.

---

# Target Audience

GroundTruth is intended for:

- Property owners undertaking construction projects
- Homeowners seeking planning or building advice
- Small contractors and tradespeople
- Small businesses conducting building works

While the initial scope focuses on small-scale residential projects, the platform may later expand to support larger developments.

---

# Core Features

## Map

### Address Search

Users can search for a property address and display it on an interactive map.

### Planning Zones and Overlays

Users can enable map layers showing planning zones and overlays that affect a property.

Features include:

- Overlay visualisation
- Zone visualisation
- Property-specific planning information

---

## Projects

### Create Projects

Users can create projects containing:

- Name
- Description
- Property address
- Project details

### Project Context

Each project stores contextual information including:

- Planning information
- Building requirements
- Cost estimates
- Notes and supporting information

### Checklist and Roadmap

GroundTruth generates a project roadmap outlining:

- Required approvals
- Recommended actions
- Construction milestones

Users can:

- View tasks
- Edit tasks
- Tick off completed items

### Contractor Portal

Users can invite contractors to collaborate on a project.

Contractors can:

- Update project progress
- Modify roadmaps
- Keep owners informed of current status

---

## AI Chat

An AI assistant will be available within each project.

The AI assistant can:

- Answer project-specific questions
- Explain planning requirements
- Explain building requirements
- Identify constraints and risks
- Discuss project costs
- Use only the current project's context when generating responses

---

## Static Information Library

### Technical FAQ

A collection of predefined guidance articles covering common construction proposals.

### Planning Overlay Definitions

Simple explanations of major Victorian planning overlays, including:

- What they mean
- What restrictions they impose
- Key considerations for property owners

---

# Problem Statement

Property owners often struggle to determine:

- Whether a planning permit is required
- Whether a building permit is required
- What constraints apply to their project
- How to obtain required approvals
- What additional local requirements exist
- What the project is likely to cost

GroundTruth addresses these challenges by providing a centralised, easy-to-understand guide for Victorian construction projects.

---

# Technical Design

## Persistent Data Storage

GroundTruth stores user and project data permanently between app launches.

### Users

Each user has a persistent account containing:

- Profile information
- Authentication details
- Saved projects

### Projects

Each project contains:

- Name
- Description
- Associated property
- Checklist
- Project status
- AI chat history
- Notes
- Uploaded documents

Users can:

- Create projects
- Edit projects
- Delete projects

A single user may own multiple projects.

---

## External Web Services

GroundTruth relies on several external APIs.

### Geocoding Services

Converts property addresses into map coordinates.

Used for:

- Address search
- Property lookup
- Map navigation

### Vicmap Planning Data

Used to retrieve:

- Planning zones
- Planning overlays
- Property-specific planning information

### AI Service Provider

An AI provider such as:

- OpenAI
- Anthropic
- Alternative large language model platforms

This service powers the in-app AI assistant.

### Supplier APIs

Supplier pricing APIs will be used to estimate material costs.

Potential suppliers include:

- Bunnings Warehouse
- Other building material providers

This enables more accurate and current project cost estimates.

---

# Technologies

## MapKit

Used for:

- Rendering maps
- Displaying properties
- Visualising planning overlays and zones

## CoreLocation

Used for:

- Geocoding addresses
- Resolving search locations
- Coordinate management

## SwiftData

Provides:

- Data persistence
- Local project storage
- User data management

## CloudKit

Provides:

- Project collaboration
- Shared contractor access
- Real-time project updates

## Security Framework (Keychain Services)

Used for:

- Secure credential storage
- Authentication tokens
- API key protection

## URLSession and Swift Concurrency

Used for:

- API communication
- Network requests
- Async data handling

## PDFKit

Enables:

- Viewing PDFs
- Uploading permits
- Uploading plans and documents

## UserNotifications

Provides alerts for:

- Contractor updates
- Upcoming deadlines
- Project reminders

---

# Minimum Viable Product (MVP)

The MVP will include:

- User registration and login
- Authentication system
- Project creation workflow
- AI-generated project roadmap/checklist
- Editable project roadmap
- Static FAQ section with at least three entries

---

# Development Roadmap

## Phase 0

### Week 5

- Finalise project scope
- Submit proposal

---

## Phase 1

### Week 6

Implement core application structure:

- Home screen
- Projects screen
- Profile screen
- FAQ section

### Week 7

Implement:

- User authentication
- Login/sign-up functionality

---

## Phase 2

### Week 8

Build UI components:

- Forms
- Map screen
- Chat screen
- Project views

### Week 9

- Continue UI implementation

---

## Phase 3

### Week 10

Integrate external APIs:

- Address search
- AI assistant
- Planning overlays
- Supplier pricing services

### Week 11

- Continue API integration

### Week 12

Implement AI context architecture so the assistant can use project-specific information.

---

## Phase 4

### Week 13

- Testing
- Quality assurance
- Deployment preparation

### Week 14

- Final submission

---

# Future Enhancements

If time permits, the following features may be added.

## PDF Project Reports

Generate downloadable and shareable project summaries.

## Home Screen Widgets

Display:

- Current project status
- Next required action
- Upcoming milestones

## Siri Shortcuts and App Intents

Examples:

> "Hey Siri, what's the status of my deck project?"

Allow users to interact with GroundTruth through Siri using natural language.

---

# References

_References to be added during implementation and research phases._
