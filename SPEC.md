# Product Specification Document

## 1. Product Vision

Feynman is an intelligent learning companion that transforms how people acquire and retain knowledge. By combining the proven Feynman Technique—explaining concepts in simple terms—with adaptive spaced repetition, AI-powered feedback, and engaging gamification, the product creates a virtuous cycle of active learning. Users don't just passively consume content; they actively engage with it, explain it, test themselves, and track their mastery over time. The vision is to make deep, lasting understanding accessible to anyone willing to invest a few focused minutes each day.

---

## 2. Problem Statement

Traditional learning methods suffer from fundamental inefficiencies. Passive consumption of lectures, videos, or reading creates an illusion of understanding that rarely translates to genuine mastery. Students spend hours reviewing material only to forget most of it within weeks. Without immediate feedback, learners cannot identify gaps in their comprehension until it's too late. Moreover, the lack of structured review leads to either over-reviewing (wasting time) or under-reviewing (forgetting material). The absence of engagement mechanisms makes the learning process feel solitary and demotivating, causing many to abandon their educational goals altogether.

---

## 3. Target Audience

The primary audience comprises lifelong learners, students at all levels, and professionals pursuing skill development. This includes university students preparing for exams, professionals learning new technologies or methodologies, hobbyists exploring new domains, and anyone who values genuine understanding over superficial familiarity. Users typically have access to smartphones and prefer learning in short, focused sessions throughout their day. They are motivated by visible progress, appreciate data-driven insights, and respond well to gamified experiences that acknowledge their effort and achievement.

---

## 4. Core Value Proposition

Feynman delivers personalized, active learning that adapts to each user's pace and goals. The product provides immediate, AI-driven feedback that helps users identify exactly what they understand and what needs reinforcement. The spaced repetition system ensures optimal memory retention with minimal wasted effort. The Feynman Technique sessions force users to articulate their understanding, revealing gaps that passive review would miss. Combined with automated generation of quizzes, flashcards, and mind maps from any source material, the product transforms any learning moment into an active engagement with the material.

---

## 5. Functional Capabilities

### Content Ingestion

Users can create learning materials from six distinct source types: audio recordings captured directly or uploaded from files, PDF documents, YouTube videos via URL, web articles accessed through links, images containing text, and plain text input. Each source undergoes intelligent processing that extracts the core content, generates timestamps for audio and video, produces summaries, and structures the material for active learning activities.

### Note Management

Notes serve as the central organizing unit for all learning content. Each note contains the source material, AI-generated summary, structured content sections, key definitions, examples, and tags. Users can organize notes into color-coded folders with customizable icons. Notes support archiving and pinning for quick access. Full-text search across all notes enables rapid retrieval of specific content.

### Feynman Technique Sessions

The flagship learning activity guides users through explaining a topic as if teaching someone else. Users choose between text-based explanations or voice recordings. The AI analyzes each attempt across four dimensions: clarity of expression, accuracy of the explanation, structural coherence, and use of effective examples. Feedback includes overall assessment, specific strengths, areas for improvement, and concrete suggestions for enhancement. Sessions track multiple attempts over time, displaying progress toward mastery with a clarity score that reflects understanding depth.

### Flashcard System

AI automatically generates flashcards from note content. Each flashcard supports front-back format with optional hints. The spaced repetition algorithm adapts to individual performance, scheduling reviews at optimal intervals to maximize retention while minimizing effort. The system handles cards in various states: new cards being learned, cards in active review, and cards that have lapsed and require re-learning. Progress tracking shows per-card statistics including ease factor, interval, repetition count, and lapse count.

### Quiz Generation

Tests are automatically generated from note content with multiple question formats: multiple choice, true/false, and fill-in-the-blank. Questions are tagged with difficulty levels (easy, medium, hard). Users complete quizzes with timed responses, receiving immediate feedback on each answer with explanations. Score history tracks best performance, allowing users to monitor improvement over time.

### Mind Map Visualization

Concept relationships are extracted and displayed as interactive mind maps with hierarchical node structures. Each node represents a concept with optional descriptions. Users can expand or collapse branches, zoom and pan across the map, and customize node colors. The visualization helps users understand the overall structure of a topic and see how ideas connect.

### AI Chat Assistant

An conversational AI allows users to ask questions about their notes, request clarifications on specific points, or explore topics in more depth. The chat interface provides contextual responses based on the source material, enabling personalized tutoring without requiring human involvement.

### Gamification Engine

Users earn experience points through activities including completing Feynman sessions, reviewing flashcards, taking quizzes, and maintaining daily streaks. A leveling system unlocks new capabilities and recognition as users progress. Achievement badges recognize milestones: creating the first note, reaching ten or fifty notes, maintaining seven-day or thirty-day streaks, achieving perfect quiz scores, mastering flashcard decks, and completing Feynman sessions at various mastery levels.

### Daily Goals

Users set personalized targets for three metrics: notes created per day, flashcards reviewed per day, and total study time in minutes. The system tracks daily progress toward these goals and provides reminders to help users stay on schedule.

### Progress Tracking

A comprehensive dashboard displays learning statistics including current streak, longest streak ever achieved, total study time accumulated, current level and experience points, progress toward the next level, and upcoming review schedule. The timeline view shows scheduled activities for the day, including flashcard reviews due and Feynman sessions ready for practice.

---

## 6. Primary User Flows

### Content Creation Flow

The user initiates by selecting a source type from the home screen. For audio, they either record directly or upload an existing file. For PDFs, they select a document from their device. For YouTube or web sources, they paste a URL. The system displays a title entry dialog, then transitions to a processing screen showing real-time progress through stages of upload, transcription, and content generation. Upon completion, the user is taken to the note detail view where they can explore the generated content, start a Feynman session, generate flashcards, or create a quiz.

### Active Learning Flow

The user opens a note from their library and selects their preferred learning activity. For Feynman sessions, they choose a topic from the note and begin explaining either by typing or recording voice. The AI analyzes their explanation and returns detailed feedback with scores and suggestions. Users iterate until they achieve a satisfactory clarity score, building mastery over time. For flashcard review, users see cards due for today, flip each card to reveal the answer, and rate their recall quality. The system schedules the next review based on their response. For quizzes, users answer questions and receive immediate feedback, with results showing their score and areas needing attention.

### Progress Monitoring Flow

The dashboard presents an overview of current status: streak, daily goal progress, recent activity, and upcoming reviews. Tapping on specific metrics reveals detailed breakdowns showing historical trends, performance by subject area, and recommendations for areas requiring attention.

---

## 7. Secondary & Supportive Flows

### Onboarding Flow

First-time users encounter a welcome sequence that introduces core concepts, particularly the Feynman Technique and spaced repetition. The onboarding establishes initial preferences for daily goals and notification settings, then guides users to create their first note or explore sample content.

### Settings Management

Settings cover account management including profile information and authentication, notification preferences for review reminders and streak alerts, appearance customization for themes and display options, language selection, and accessibility configurations. Legal documents including terms of service and privacy policy are accessible from this area.

### Folder Organization

Users create folders with custom names, colors, and icons. Notes can be moved between folders or exist without a folder assignment. Folders display note counts and support deletion, with deleted folders recoverable within a grace period.

### Conflict Resolution

When sync conflicts occur between local changes and server data, the system presents a clear comparison showing both versions. Users choose which version to keep or merge elements from each. Conflict history is maintained for audit purposes.

### Error Recovery

Processing failures are handled gracefully with informative error messages and retry options. Users can attempt reprocessing of failed content or delete and recreate notes. The error boundary system prevents crashes from disrupting the entire application.

---

## 8. Business Logic & Rules

### Spaced Repetition Algorithm

The algorithm uses a modified SM-2 approach. New cards begin in learning mode with short intervals. Upon successful graduation, cards enter review mode with intervals determined by ease factor and performance ratings. Failed cards (rated "again") enter relearning with reduced intervals. Ease factor adjusts based on performance, ranging from a minimum of 1.3 to a maximum of 3.0. The system calculates intervals exponentially based on repetition count and ease factor.

### Mastery Thresholds

Feynman session mastery is determined by clarity scores. Scores below 60 indicate "needs work," 60-69 shows "getting started," 70-79 reflects "making progress," 80-89 represents "nearly there," and 90 and above marks "mastered." These thresholds inform both user feedback and streak calculations.

### Streak Logic

Streaks increment for any day with at least one learning activity. Missing a day resets the current streak to zero while preserving the longest streak record. The system considers local timezone for day boundaries.

### Experience Point Awards

XP is awarded across activities: completing a Feynman session grants points proportional to the clarity score achieved, reviewing flashcards awards base points plus bonuses for streaks, taking quizzes grants points based on score percentage, and creating new notes provides initial XP with bonus for including certain content types.

### Sync Strategy

The system maintains offline-first capability with local database storage. Background synchronization batches changes and uploads when connectivity is available. Conflict detection uses version vectors to identify concurrent modifications. Users are notified of sync status through visual indicators in the interface.

---

## 9. Edge Cases & Boundary Conditions

### Large File Handling

Audio files up to 500MB are accepted, with chunked upload support for unreliable connections. Processing time scales with file length, with progress updates provided throughout.

### Content Processing Failures

When transcription or content generation fails, the system retains the original file and allows retry. Persistent failures present users with options to modify the source material or convert to a simpler note type.

### Network Interruption During Learning

In-progress sessions are saved locally, allowing users to resume without data loss. Queued activities continue processing when connectivity returns.

### Clock Skew Handling

Timestamps are validated against current time, with future dates adjusted to prevent display anomalies. This ensures consistent date formatting regardless of device clock accuracy.

### Multi-Device Synchronization

When the same account is used on multiple devices, the sync engine reconciles changes with last-write-wins logic for most fields and explicit conflict resolution for critical data.

### Empty States

Each feature area provides meaningful empty states with clear calls to action: guidance to create the first note, start the first Feynman session, or record the first audio.

---

## 10. Success Criteria

### Engagement Metrics

Daily Active Users demonstrate consistent usage patterns with sessions occurring across multiple hours of the day. Monthly Active Users show returning usage patterns over consecutive weeks. Session duration indicates sustained engagement with learning activities rather than casual opening and closing.

### Learning Outcomes

Mastery progression shows users advancing through clarity score thresholds over repeated Feynman attempts on the same topic. Retention rates measure how well users recall material after standard intervals. Quiz performance improvement tracks score changes across multiple attempts on the same quiz.

### Habit Formation

Streak maintenance demonstrates the percentage of users who maintain streaks beyond seven days, thirty days, and beyond. Daily goal completion rates measure how often users meet their self-set targets. Return rate indicates what percentage of users return to the app within twenty-four hours of their previous session.

### Content Growth

Notes created per user shows the breadth of topics being studied. Source type distribution indicates which ingestion methods users prefer. Feature adoption across Feynman sessions, flashcards, quizzes, and mind maps reveals which activities resonate most.

### System Health

Sync success rates measure reliable data synchronization across devices. Error rates during content processing indicate system reliability. Crash-free sessions demonstrate application stability.
