# Contributing Guide - Amica Project

Amica is a women's safety and security application developed as a team project. This guide explains how beginner developers should work with branches, issues, commits, pull requests, and CI/CD.

The most important rule is simple:

```text
Do your work in a separate branch, then open a pull request to dev.
```

## Branch Strategy

We use branches to keep production-ready code separate from active development work.

- `main`  
  Production/demo-ready branch. This branch should contain stable code only. Do not push directly to `main`.

- `dev`  
  Main development branch. Completed features are merged into `dev` through pull requests.

- `feature/*`  
  Use for new features.

- `bugfix/*`  
  Use for fixing bugs.

- `docs/*`  
  Use for documentation updates.

- `ci/*`  
  Use for GitHub Actions, CI/CD, or workflow changes.

- `refactor/*`  
  Use for code cleanup that does not change app behavior.

Do not push directly to `main`.  
Do not push directly to `dev` unless it is a very small documentation change approved by the team.

## Branch Naming Convention

Use this format:

```text
<type>/<issue-number>-short-description
```

Examples:

```text
feature/10-login-ui
feature/14-home-dashboard
feature/19-journey-timer-screen
bugfix/22-fix-login-validation
docs/25-update-screen-list
ci/30-update-flutter-ci
refactor/34-clean-auth-widgets
```

If there is no issue number yet, create or ask for an issue first. Issues help the team know why a branch exists.

## Beginner Workflow

Follow these steps when starting any task.

1. Make sure you are on `dev`.

```bash
git checkout dev
git pull origin dev
```

2. Create a new branch from `dev`.

```bash
git checkout -b feature/10-login-ui
```

3. Make your changes.

For example, if you are working on the login UI, edit files inside:

```text
lib/features/auth/
lib/core/widgets/
```

4. Check what changed.

```bash
git status
git diff
```

5. Run relevant checks.

```bash
flutter pub get
flutter analyze
flutter test
```

6. Stage and commit your changes.

```bash
git add lib/features/auth lib/core/widgets test
git commit -m "Create login UI"
```

7. Push your branch.

```bash
git push origin feature/10-login-ui
```

8. Open a pull request on GitHub.

The pull request should target:

```text
base branch: dev
compare branch: your feature branch
```

## Commit Message Examples

Good commit messages are short and clear.

Good examples:

```text
Create login UI
Add journey timer screen
Update emergency contacts form
Fix phone number validation
```

Avoid vague messages:

```text
changes
update
final
fix
my work
```

## Pull Request Guidelines

Before opening a pull request, make sure:

- Your branch is created from the latest `dev`.
- Your pull request targets `dev`, not `main`.
- Your code or documentation matches the issue you are solving.
- You did not commit private files, API keys, Firebase config files, tokens, or keystores.
- You ran relevant checks, or you explained why you could not run them.
- Your pull request description explains what changed.

Example pull request summary:

```text
This PR creates the login UI for the mobile app.

Changes:
- Adds login form fields
- Adds login button
- Adds basic validation messages
- Reuses the shared custom text field widget

Checks:
- flutter analyze
- flutter test
```

## Issue Workflow

Each task should have a GitHub issue.

An issue usually includes:

- A clear title
- A short description
- A checklist
- Labels such as `frontend`, `uiux`, `firebase`, or `priority-high`
- One assignee
- A milestone

Example issue title:

```text
Create journey timer screen
```

Example checklist:

```text
- [ ] Add journey duration input
- [ ] Add destination input
- [ ] Show countdown timer
- [ ] Add I am safe button
- [ ] Prepare UI for SOS trigger integration
```

When you open a pull request, link the issue in the PR description:

```text
Closes #12
```

## CI/CD Basics

CI/CD means GitHub automatically checks the project when code is pushed or a pull request is opened.

For this repository, CI may run commands like:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

If CI fails:

1. Open the failed GitHub Actions run.
2. Read the error message.
3. Fix the problem in your branch.
4. Commit and push again.

Do not ignore failed CI. Ask the team for help if the error is confusing.

## Mobile App Development Notes

This repository contains the Flutter mobile app.

Main areas:

- `lib/core/` for shared constants, theme, utilities, and widgets
- `lib/features/auth/` for login, signup, and password reset
- `lib/features/home/` for dashboard UI
- `lib/features/emergency_contacts/` for trusted contacts
- `lib/features/journey/` for Smart Journey Timer
- `lib/features/sos/` for SOS alert screens
- `lib/features/fake_call/` for fake call deterrent screens
- `lib/features/plate_scan/` for Scan Before You Ride UI
- `lib/services/` for shared Firebase, location, and notification service placeholders
- `test/` for widget and unit tests

When adding Flutter code:

- Keep widgets small and readable.
- Reuse shared widgets from `lib/core/widgets/`.
- Keep feature-specific code inside that feature folder.
- Add placeholder comments when real Firebase or device integration will be added later.
- Add or update tests when behavior changes.

## Secrets and Private Data

Never commit:

- API keys
- Firebase credentials
- `google-services.json`
- `GoogleService-Info.plist`
- Private keys
- Keystores
- Access tokens
- Real user location data
- Real phone numbers from users

If you accidentally commit a secret, tell the team immediately. Do not try to hide it with another commit.

## Asking for Help

Ask for help when:

- You are not sure which branch to use.
- You do not understand an issue.
- Flutter commands fail and you cannot understand why.
- You need Firebase or device permission setup.
- You are unsure whether a file contains private data.

A good help message includes:

```text
I am working on issue #12.
My branch is feature/12-login-ui.
I ran flutter analyze and got this error: <paste error here>.
I already checked the widget import and route name.
```

## Quick Reference

Common commands:

```bash
git checkout dev
git pull origin dev
git checkout -b feature/12-short-description
git status
git add .
git commit -m "Short clear message"
git push origin feature/12-short-description
```

Before requesting review:

```bash
flutter analyze
flutter test
```
