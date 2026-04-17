# UniFind Claims Feature Implementation Guide

## Overview
Users can now claim lost and found items through the enhanced **ItemDetailsScreen**. This feature allows users to submit claims with optional supporting messages for items they believe belong to them.

## Features

### User Interface
- **Claim Button**: Primary call-to-action button on item details screen
- **Claim Dialog**: Modal dialog for users to optionally add a message with proof
- **Status Indicators**: Display current claim status:
  - **No Claim**: Shows "Claim This Item" button (blue)
  - **Pending**: Shows "Claim Pending - Awaiting Approval" status (orange)
  - **Approved**: Shows "Claim Approved" status (green)
  - **Rejected**: Shows "Claim Rejected" status (red)
  - **Own Item**: Shows "This is your item" for item creators (disabled state)

### Admin Notifications (NEW)
- **Automatic Alerts**: Admin is automatically notified when a claim is submitted
- **Claim Details**: Notification includes claimant name, email, item title, and claim message
- **Email Records**: System records claimant and item owner emails for admin follow-up
- **Status Tracking**: Admin can mark notifications as read/archived for organization

### Smart Features
- ✓ Prevents users from claiming their own items
- ✓ Prevents duplicate claims (one claim per user per item)
- ✓ Optional claim message/proof field
- ✓ Real-time claim status updates using FutureBuilder
- ✓ Automatic admin notification system
- ✓ Error tracking and logging

## Database Setup

### Required SQL Schema

Execute both SQL files in Supabase to create the necessary tables:

#### 1. Claims Table (Required)
Run `claims_schema.sql` in your Supabase SQL Editor:

```sql
-- Creates the claims table with:
-- - item_id: Reference to lost/found item
-- - claimant_id: User making the claim  
-- - claim_details: Optional message/proof from claimant
-- - status: PENDING, APPROVED, REJECTED, WITHDRAWN
-- - admin_notes: Notes from admin reviewer
-- - Unique constraint: prevents duplicate claims per user per item
```

#### 2. Notifications Table (Recommended)
Run `notifications_schema.sql` in your Supabase SQL Editor:

```sql
-- Creates automatic admin alerts when claims are submitted
-- - Records claimant info for admin reference
-- - Tracks read/unread status
-- - Maintains audit trail of claim events
```

### Column Names (IMPORTANT!)
Verify your database uses these exact column names:
- ✓ `claimant_id` (NOT `user_id`)
- ✓ `claim_details` (NOT `claim_message`)
- ✓ `admin_notes` (NOT `notes`)

## Code Changes

### Modified Files
- **lib/screens/item_details.dart**
  - Converted from StatelessWidget to StatefulWidget
  - Added claim status tracking
  - Added claim dialog for optional messages
  - Added claim submission logic
  - Added visual status indicators

### Key Methods

#### `_getUserClaimStatus()`
Queries the `claims` table to get the user's current claim status for the item.

#### `_submitClaim(BuildContext context)`
Inserts a new claim record into Supabase with:
- Item ID
- User ID
- Optional claim message
- Default status: 'PENDING'

#### `_showClaimDialog(BuildContext context)`
Displays a modal dialog allowing users to:
- Confirm their claim intent
- Optionally add a message/proof

#### `_buildClaimButton(BuildContext context, String? claimStatus)`
Renders appropriate UI based on claim status:
- Enabled blue button if no claim exists
- Different status indicators for each claim state
- Disabled state if user is the item creator

## User Flow

1. User views an item in the dashboard
2. User taps on the item to see details
3. On the details screen, user sees the "Claim This Item" button (if eligible)
4. User taps the button
5. A dialog appears asking to confirm and optionally add a message
6. User submits the claim
7. Claim is saved with 'PENDING' status
8. Button changes to show "Claim Pending - Awaiting Approval"
9. Admin reviews and approves/rejects the claim
10. Button updates to show final status

## Error Handling

- Handles duplicate claims with PostgreSQL unique constraint
- Shows user-friendly error messages via SnackBar
- Logs detailed error information for debugging
- Gracefully handles null/missing user authentication

## Testing

Before deployment:

1. **Test Claim Submission**
   ```bash
   flutter test
   ```

2. **Test on Device/Emulator**
   ```bash
   flutter run
   ```

3. **Manual Testing Checklist**
   - [ ] Can submit a claim with a message
   - [ ] Can submit a claim without a message
   - [ ] Cannot claim own item (button disabled)
   - [ ] Cannot create duplicate claim (error shown)
   - [ ] Claim status updates in real-time after submission
   - [ ] Status indicator updates when admin approves/rejects

## Future Enhancements

- Admin dashboard to view/manage claims
- Email notifications for claim status changes
- Claim withdrawal functionality
- Claim history view for users
- Attachment support for proof documents
- User reputation/verified status system
- Arbitration system for disputed claims

## Troubleshooting

### Claims table not found error
- Ensure you've run the SQL schema creation script
- Check RLS policies are configured correctly

### Duplicate claim error
- User has already claimed this item
- Unique constraint prevents multiple claims per user per item

### Cannot submit claim
- Verify user is authenticated
- Check Supabase permissions/RLS policies
- Review browser console for detailed error logs

## Related Files
- [ItemDetailsScreen](lib/screens/item_details.dart)
- [Main App Configuration](lib/main.dart)
- [Database Documentation](README.md)
