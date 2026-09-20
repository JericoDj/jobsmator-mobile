import fs from 'fs';
const path = 'lib/features/profile/job_preferences_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const oldHeader = `        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'The ranking uses these to score fit and flag listings that miss.',
            style: context.type.body.copyWith(color: c.muted),
          ),
          const SizedBox(height: JmSpace.x6),`;

const newHeader = `        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'The ranking uses these to score fit and flag listings that miss.',
            style: context.type.body.copyWith(color: c.muted),
          ),
          const SizedBox(height: JmSpace.x6),
          InkWell(
            onTap: () => {
              context.push('/interests');
            },
            borderRadius: JmRadius.mdR,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: JmSpace.x2, horizontal: JmSpace.x1),
              child: Row(
                children: [
                  Icon(Icons.interests_outlined, color: c.muted),
                  const SizedBox(width: JmSpace.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Job Interests', style: context.type.uiStrong),
                        const SizedBox(height: 2),
                        Text(d.interests.isEmpty ? 'No interests yet' : d.interests.join(', '), style: context.type.meta),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: c.faint),
                ],
              ),
            ),
          ),
          const SizedBox(height: JmSpace.x4),
          const Divider(),
          const SizedBox(height: JmSpace.x6),`;

code = code.replace(oldHeader, newHeader);
fs.writeFileSync(path, code);
console.log("Patched JobPreferencesScreen again");
