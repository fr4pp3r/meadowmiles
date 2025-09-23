# User Verification Feature Setup

### 2. Configure Storage Permissions

Since you're using Firebase Authentication (not Supabase Auth), you have two options:

#### Option A: Make Bucket Public (Simplest for Firebase Auth)

1. Go to your Supabase project dashboard
2. Navigate to Storage → `id-storage` bucket
3. Click on **Settings** for the bucket
4. **Disable RLS** for this bucket
5. Set the bucket to **Public** (this allows viewing images without authentication)

This is the simplest approach and works well since:
- Your app handles authentication through Firebase
- Only authenticated users can upload (controlled by your app logic)
- Images are viewable without complex signed URL generation

#### Option B: Keep Bucket Private with Signed URLs

1. Keep the bucket **Private**
2. **Disable RLS** for this bucket
3. The app will automatically generate signed URLs for viewing images

This approach provides additional security but adds complexity.

#### Option B: Use Service Role (Advanced)

If you prefer to keep RLS enabled, you would need to:

1. Use the Supabase service role key in your backend
2. Create a backend API endpoint for image uploads
3. Handle uploads server-side with proper authentication

For most cases, **Option A is recommended** as it's simpler and secure when combined with Firebase Auth.nes the setup and functionality of the user verification feature implemented in MeadowMiles.

## Overview

The user verification feature allows users to submit their ID documents and selfies for account verification. The verification process includes:

1. **Privacy Policy Agreement**: Users must agree to data collection and processing
2. **ID Document Upload**: Users upload a photo of their government-issued ID
3. **Selfie Capture**: Users take a selfie for identity verification
4. **Admin Review**: Verification requests are reviewed by administrators
5. **Status Updates**: Users are notified of verification approval/rejection

## Files Created/Modified

### New Files:
- `lib/models/support_ticket_model.dart` - Support ticket data model
- `lib/services/verification_service.dart` - Verification business logic
- `lib/components/verification_dialog.dart` - User verification UI
- `lib/components/support_ticket_card.dart` - Admin ticket management UI

### Modified Files:
- `lib/pages/profile/profile.dart` - Added verification button functionality
- `lib/pages/admin/admin_support_tab.dart` - Updated to show support tickets

## Supabase Setup Required

### 1. Create Storage Bucket

You need to create a storage bucket named `id-storage` in your Supabase project:

1. Go to your Supabase project dashboard
2. Navigate to Storage
3. Create a new bucket named `id-storage`
4. Set the bucket to be private (not public)

### 2. Configure RLS Policies

Set up Row Level Security policies for the bucket:

```sql
-- Allow authenticated users to upload to id-storage
CREATE POLICY "Allow authenticated uploads" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'id-storage' 
  AND auth.role() = 'authenticated'
);

-- Allow service role to read/delete from id-storage
CREATE POLICY "Allow service role access" ON storage.objects
FOR ALL USING (
  bucket_id = 'id-storage' 
  AND auth.role() = 'service_role'
);
```

### 3. Firestore Collections

The following Firestore collection will be automatically created:
- `support_tickets` - Stores all support tickets including verification requests

## Usage

### For Users:
1. Go to Profile page
2. If not verified, click "Start Verification" button
3. Read and accept privacy policy
4. Upload ID document (camera or gallery)
5. Take selfie (camera or gallery)
6. Submit for review

### For Admins:
1. Go to Admin Dashboard > Support tab
2. View verification requests in the "Verification" tab
3. Click on images to view full-size
4. Approve or reject with reason
5. User verification status is automatically updated

## Security Features

- Images are stored in private Supabase bucket
- Only authenticated users can upload
- Images are automatically deleted after 30 days (implement separately)
- Support tickets track all verification activities
- Admin actions are logged with timestamps

## Dependencies

The feature uses existing dependencies:
- `supabase_flutter` - For image storage
- `cloud_firestore` - For support tickets
- `image_picker` - For camera/gallery access
- `provider` - For state management

## Error Handling

- Network connectivity checks
- Image upload failure handling
- Firestore operation error handling
- User-friendly error messages
- Fallback for missing images

## Troubleshooting

### Common Issues

#### 1. "StorageException: new row violates row-level security policy"

**Cause**: RLS is enabled on the `id-storage` bucket, but you're using Firebase Auth instead of Supabase Auth.

**Solution**: 
1. Go to Supabase Dashboard → Storage → `id-storage` bucket → Settings
2. Disable RLS for this bucket
3. Ensure bucket remains Private (not Public)

#### 2. "Failed to upload images"

**Possible causes**:
- Network connectivity issues
- Bucket doesn't exist
- Incorrect bucket permissions
- File size too large

**Solutions**:
- Check internet connection
- Verify `id-storage` bucket exists in Supabase
- Disable RLS as mentioned above
- Ensure images are under 50MB

#### 3. Images not displaying in admin panel

**Cause**: Bucket is set to private but RLS policies don't allow reading.

**Solution**: 
- If RLS is disabled: Should work automatically
- If RLS is enabled: Add read policies or disable RLS

### Testing the Feature

1. Create a test user account
2. Go to Profile → Click "Start Verification"
3. Complete the verification flow
4. Check Admin Dashboard → Support tab for the ticket

## Privacy Compliance

- Clear privacy policy displayed to users
- Explicit consent required before data collection
- Secure storage of sensitive documents
- Audit trail of admin actions
- Data retention policy (30 days)