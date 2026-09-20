import fs from 'fs';
const path = 'lib/features/upload/upload_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const oldBottom = `      bottom: latest == null
          ? null
          : PrimaryButton(
              label: 'Continue with \${latest.filename.length > 24 ? 'this resume' : latest.filename}',
              large: true,
              icon: Icons.arrow_forward_rounded,
              onPressed: resumes.uploading ? null : () => context.go(AppRoutes.interests),
            ),`;

const newBottom = `      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: JmSpace.x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (latest != null) ...[
                PrimaryButton(
                  label: 'Continue with \${latest.filename.length > 24 ? 'this resume' : latest.filename}',
                  large: true,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: resumes.uploading ? null : () => context.go(AppRoutes.interests),
                ),
                const SizedBox(height: JmSpace.x2),
              ],
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text('Skip for now', style: context.type.meta),
              ),
            ],
          ),
        ),
      ),`;

code = code.replace(oldBottom, newBottom);
fs.writeFileSync(path, code);
console.log("Patched UploadScreen");
