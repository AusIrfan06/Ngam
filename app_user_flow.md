# Ngam App: User Flow (For Report)

This document contains the structural User Flows for the Ngam application. You can use these diagrams and explanations directly in your system analysis or design report. 

*(**Tip**: You can screenshot the generated charts below and paste them into your report!)*

---

## 1. High-Level Registration & Onboarding Flow

This flow shows how a new user enters the system, registers, and utilizes the Dual-Role architecture.

```mermaid
flowchart TD
    Start([Launch App]) --> Splash[Splash Screen]
    Splash --> AuthCheck{Is Logged In?}
    
    AuthCheck -- Yes --> RoleCheck{Current Role?}
    AuthCheck -- No --> Login[Login / Register Screen]
    
    Login --> Method{Login Method}
    Method -- Google --> GAuth[Supabase Google OAuth]
    Method -- Email --> EAuth[Email & Password Auth]
    
    EAuth --> ChooseRole{Choose Role}
    ChooseRole -- Customer --> CreateCust[Create Customer Profile]
    ChooseRole -- Runner --> RunnerForm[Submit Runner Verification Form]
    
    GAuth --> CreateCust
    RunnerForm --> Verify(System Verifies IC & Vehicle)
    
    CreateCust --> CustHome
    Verify --> RunnerHome
    
    RoleCheck -- Customer --> CustHome[Customer Home Screen]
    RoleCheck -- Runner --> RunnerHome[Runner Home Screen]
    
    CustHome --> ProfileToggle[Toggle to Runner via Profile]
    ProfileToggle --> RunnerForm
    
    RunnerHome --> ProfileToggleCust[Toggle to Customer via Profile]
    ProfileToggleCust --> CustHome
```

---

## 2. Customer Journey (Requesting a Gig)

This diagram illustrates the step-by-step process a Customer takes to post a job and get it completed by a Runner.

```mermaid
flowchart TD
    Start([Customer Home]) --> Action{Choose Action}
    
    Action -- Post a Task --> Form[Fill Task Form: Title, Category, Bounty]
    Form --> SelectLoc[Select Location via Map Picker]
    SelectLoc --> Escrow[System holds Bounty in Escrow]
    Escrow --> Broadcast[Gig status = OPEN]
    Broadcast --> Wait[Wait for Runner to Accept]
    
    Action -- Browse Map --> ViewMap[View Nearby Runners & Services]
    ViewMap --> BookService[Book a Specific Service]
    BookService --> Pending[Gig status = PENDING]
    Pending --> WaitRunner[Wait for Specific Runner to Accept]
    
    Wait -- Runner Accepts --> Locked[Gig status = LOCKED]
    WaitRunner -- Runner Accepts --> Locked
    
    Locked --> Review[Customer Reviews Runner Profile]
    Review -- Reject --> Broadcast
    Review -- Approve --> InProgress[Gig status = IN-PROGRESS]
    
    InProgress --> Chat[Communicate via Real-time Chat]
    Chat --> RunnerDelivers(Runner Marks as Delivered)
    RunnerDelivers --> VerifyTask[Customer Inspects Work]
    
    VerifyTask -- Not Satisfied --> Dispute[Dispute / Chat Runner]
    VerifyTask -- Satisfied --> Confirm[Press Confirm Completed]
    
    Confirm --> Release[Escrow releases Funds to Runner]
    Release --> Done([Gig COMPLETED])
```

---

## 3. Runner Journey (Finding & Executing Jobs)

This diagram shows how a Runner finds jobs on the map, executes them, and receives payment via Ngam Pay.

```mermaid
flowchart TD
    Start([Runner Home]) --> Action{Choose Action}
    
    Action -- Create Service Ad --> PostService[Fill Service Name & Price]
    PostService --> AdLive[Service Ad is Live on Map]
    AdLive --> WaitBooking[Wait for Direct Customer Booking]
    
    Action -- Browse Map --> Map[View Customer Gigs]
    Map --> ViewGig[View Gig Details & Distance]
    ViewGig --> Accept[Click 'Accept Job']
    
    Accept --> DBUpdate[Database Trigger: Lock Task]
    DBUpdate --> WaitCust[Wait for Customer Approval]
    
    WaitBooking -- Received Booking --> PendingView[View in PENDING Tab]
    PendingView -- Accept --> WaitCust
    PendingView -- Decline --> AdLive
    
    WaitCust -- Customer Approves --> InProgress[Gig status = IN-PROGRESS]
    WaitCust -- Customer Rejects --> Map
    
    InProgress --> DoWork[Execute Physical Task / Travel]
    DoWork --> Chat[Communicate via App Chat]
    Chat --> DoneWork[Task Finished]
    DoneWork --> PressDeliver[Press 'Mark as Delivered']
    
    PressDeliver --> WaitVerify[Wait for Customer Verification]
    WaitVerify -- Confirmed --> GetPaid[Bounty Transfer to Wallet]
    
    GetPaid --> End([Gig COMPLETED])
```

---

## How to Explain This in Your Report

If your lecturer asks you to explain the User Flow in text, you can write it like this:

### 1. Unified Authentication Flow
> *"The system uses a Unified Authentication model. When a user first opens the app, they undergo standard authentication. Upon successful login, the system evaluates their role. A unique feature of this flow is the **Dual-Role Toggle**, which allows users to seamlessly switch between the Customer dashboard and the Runner dashboard without requiring a secondary application or re-authentication."*

### 2. The Job Execution Pipeline
> *"The core business logic relies on a rigorous state-machine flow. A task begins as `OPEN` when broadcasted to the map. Once a runner intercepts the task, the state mutates to `LOCKED`. This state strictly requires the Customer's manual approval to proceed to `IN-PROGRESS`. This explicit handshake prevents unauthorized task execution and guarantees mutual agreement before the SLA countdown begins."*

### 3. Financial Escrow Flow
> *"Parallel to the user flow is the financial data flow. When a Customer creates a task, the specified bounty is immediately deducted from their digital wallet and held in a secure Escrow state. The funds only proceed to the Runner's wallet at the terminal state (`COMPLETED`), ensuring absolute financial security for both entities."*
