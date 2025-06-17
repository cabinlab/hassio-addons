# Task Package Creation Guide

This directory contains task packages for parallel agent sessions. Task packages are comprehensive instructions for other AI agents to perform specific analysis or development tasks.

## What is a Task Package?

A task package is a structured set of instructions that enables another AI agent to work independently on a specific task. It should be self-contained with all necessary context, clear objectives, and expected deliverables.

## How to Create a Task Package

### 1. Structure Your Task Package

A good task package includes:

```markdown
# [Task Title]

## Objective
Clear, one-paragraph summary of what needs to be accomplished.

## Primary Questions to Answer
- Specific question 1
- Specific question 2
- ...

## Required Context Files
List all files the agent needs to read, with full paths.

## External Documentation to Research
Links and search terms for external resources.

## Specific Analysis Tasks
Detailed breakdown of work to be done.

## Deliverables
Exact files to create and what they should contain.

## Implementation Notes
Constraints, preferences, and guidelines.
```

### 2. Include Supporting Files

Create additional files in the target directory:
- `CURRENT_STATE.md` - Document the as-is situation
- `EXAMPLES_AND_PRIORITIES.md` - Concrete examples and use cases
- `START_HERE.md` - Quick orientation guide
- `README.md` - Directory overview

### 3. Key Elements of a Good Task Package

#### Clarity
- State the model to use (Haiku, Sonnet, Opus)
- Be explicit about what to do AND what not to do
- Define success criteria

#### Context
- Provide all necessary file paths
- Include relevant documentation links
- Explain project conventions and constraints

#### Scope
- Keep tasks focused and achievable
- Break large tasks into phases if needed
- Set clear boundaries

#### Output
- Specify exact filenames for deliverables
- Define the format for questions/findings
- Indicate where files should be saved

### 4. Task Package Naming Convention

Save task packages with descriptive names and timestamps:
```
[TASK_NAME]_TASK_[YYYYMMDD_HHMMSS].md
```

Example: `CONFIG_ANALYSIS_TASK_20250609_151234.md`

### 5. Common Task Package Types

#### Analysis Tasks
- System design reviews
- Architecture decisions
- Performance optimization studies
- UX improvement analysis

#### Implementation Tasks
- Feature development
- Bug fixing sprints
- Refactoring projects
- Integration work

#### Research Tasks
- Technology evaluation
- Best practices research
- Competitive analysis
- Documentation review

### 6. Task Package Template

```markdown
# [Task Name] Task Package

## Objective
[One paragraph description of the task]

## Model Recommendation
[Specify which Claude model to use and why]

## Primary Questions to Answer
1. [Question 1]
2. [Question 2]
3. [Question 3]

## Required Context Files

### From This Repository
```
/path/to/file1
/path/to/file2
```

### External Documentation
1. [Resource 1] - [URL or search terms]
2. [Resource 2] - [URL or search terms]

## Specific Tasks

### Task 1: [Name]
[Detailed description]

### Task 2: [Name]
[Detailed description]

## Deliverables

Create the following files in `[target directory]`:
1. `FILENAME1.md` - [Description of contents]
2. `FILENAME2.md` - [Description of contents]
3. `QUESTIONS.md` - Any questions or clarifications needed

## Constraints and Guidelines
- [Constraint 1]
- [Constraint 2]
- [Guideline 1]

## Success Criteria
- [Criterion 1]
- [Criterion 2]

## Notes
[Any additional context or special instructions]
```

### 7. Working with Task Packages

#### For Task Creators
1. Test your instructions - would you be able to complete this task with only this information?
2. Include examples where helpful
3. Anticipate questions and address them
4. Review for completeness before finalizing

#### For Task Executors  
1. Start with START_HERE.md if provided
2. Read the entire task package before beginning
3. Create QUESTIONS.md early for any clarifications
4. Document assumptions made
5. Stay within defined scope

### 8. Directory Organization

```
task-packages/
├── README.md (this file)
├── [TASK_NAME]_TASK_[TIMESTAMP].md
├── [TASK_NAME]_TASK_[TIMESTAMP].md
└── templates/
    └── TASK_TEMPLATE.md
```

Target work directories (not in task-packages/):
```
memory/          # For analysis and documentation tasks
prototypes/      # For proof-of-concept work  
research/        # For research findings
decisions/       # For architectural decisions
```

## Best Practices

1. **Be Specific** - Vague instructions lead to misaligned results
2. **Provide Context** - Explain the "why" not just the "what"
3. **Set Boundaries** - Clearly define what's in and out of scope
4. **Enable Independence** - Include all needed information
5. **Plan for Questions** - Provide a clear way to handle unknowns

## Example Task Packages

See existing task packages in this directory for examples of well-structured tasks.