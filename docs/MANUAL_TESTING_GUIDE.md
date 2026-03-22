# Krate Manual Testing Guide

This guide provides step-by-step instructions for manually verifying the core UI
feedback elements, navigation, and robust background operations (like "Undo") in the Krate application.

## 1. Integrated UI Testing (Settings Debug Section)
The easiest way to verify the consistency of SnackBars, Dialogs, Modals, and Toasts is through the built-in Debug Section.

- **Navigation:** Open the app, go to `Settings` -> Expand the `Debug (UI Testing)` card.
- **SnackBars:**
  - Click `Show Info SnackBar` → Expect a default colored snackbar with an "i" icon.
  - Click `Show Success SnackBar` → Expect a green-themed snackbar with a checkmark.
  - Click `Show Error SnackBar` → Expect a red-themed snackbar with an error icon and long duration.
  - Click `Show Action SnackBar` → Expect a snackbar with a clickable action button (e.g., "Retry").
- **Dialogs & Modals:**
  - Click `Show Standard Dialog` → A standard informational M3 dialog should appear.
  - Click `Show Destructive Dialog` → A dialog with a red "Delete" button.
  - Click `Show Sync Required Alert` → The vault change dialog that blocks interaction.
  - Click `Show Quick Actions Sheet` → A mock bottom sheet representing media card actions.
  - Click `Show Season Picker Modal` → A centered dialog showcasing season selection.
- **Global Toasts:**
  - Toggle `Mock Vault Sync` → Look at the top of the screen (under the app bar). A toast should drop down showing progress. Toggle it off and the toast should animate up and away.
  - Click `Mock Import Success` → A green top-toast notifying you of a successful import.
  - Click `Mock Import Error` → A red top-toast notifying you of a failed import.

## 2. Testing "Undo" Capability (Watch Progress)
The application allows you to undo critical destructive actions to your watch progress.

### Scenario A: Marking as Watched
1. Go to your Library and find a Movie or Series that is *not* fully completed.
2. Long-press the media card to open the Quick Actions menu.
3. Select **Mark as watched**.
4. Tap **Confirm** on the dialog.
5. **Observation:** A SnackBar will appear at the bottom saying "Marked '[Title]' as watched" with an **Undo** button. The media card's badge should update immediately to show '✓' (finished).
6. **Action:** Quickly tap **Undo** on the SnackBar before it disappears.
7. **Result:** The media card should instantly revert to its original unfinished state (e.g., "1/5" or no badge).

### Scenario B: Clearing Watch History
1. Go to your Library and find a Movie or Series that you have watch progress on.
2. Long-press the media card or go to the Media Details page and open the top-right More Menu.
3. Select **Clear watch history**.
4. Confirm the destructive action.
5. **Observation:** A SnackBar appears stating "Cleared history for '[Title]'" with an **Undo** button. The media card's progress badge should disappear.
6. **Action:** Tap **Undo**.
7. **Result:** The exact previous watch progress should be fully restored on the media card and Continue Watching list.

## 3. Testing Real-World Error Scenarios

### Scenario C: No Internet on Import Search
1. Disconnect your device from Wifi/Data (enable Airplane Mode).
2. Tap the `+` FAB on the Home screen to open the Search Import Screen.
3. Type any text and submit a search.
4. **Result:** Instead of crashing, the app should display a fullscreen "No Internet Connection" empty state, or an Error SnackBar describing the socket/network failure.

### Scenario D: Storage Permission Denied
1. Go to your Android App Settings -> Krate -> Permissions. Disable Storage/Media permissions.
2. Force close the app and reopen it.
3. **Result:** You should be redirected to the Storage Setup screen. A red error SnackBar will display "Storage permission is required..." with a "Settings" action button.

## 4. Validating the "Startup Flow"
1. Completely force close the Krate app.
2. Open the Krate app.
3. **Observation:** The deep-purple KRATE splash screen should display for a **minimum of 2 seconds**.
4. Behind the scenes, the app is automatically checking for vault changes, cleaning up failed imports, and pre-fetching the homepage data. You should load straight into a fully populated Home screen.
