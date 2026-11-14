import { useState } from 'react';
import {
  Box,
  Button,
  Input,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

import type { ModuleTabProps } from './types';

type Subject = {
  ref: string;
  name: string;
  /** The suggestion's phrase, or null if none has been set */
  phrase: string | null;
  /** Whether your next spoken line will still become their suggestion */
  awaiting: boolean;
  /** Whether they can receive anything from you right now */
  reachable: boolean;
};

type SubjectsData = {
  subjects: Subject[];
};

type SubjectProps = {
  subject: Subject;
  moduleAct: ModuleTabProps<SubjectsData>['moduleAct'];
};

const SubjectEntry = (props: SubjectProps) => {
  const { subject, moduleAct } = props;
  const [text, setText] = useState('');

  const suggest = () => {
    if (!text.trim()) {
      return;
    }
    moduleAct('suggest', { ref: subject.ref, text });
    setText('');
  };

  return (
    <Section
      title={subject.name}
      buttons={
        <Button.Confirm
          icon="unlock"
          confirmContent="Release?"
          onClick={() => moduleAct('release', { ref: subject.ref })}
        >
          Release
        </Button.Confirm>
      }
    >
      <Box mb={1}>
        {subject.phrase ? (
          <>Suggestion: {subject.phrase}</>
        ) : (
          <Box inline color="label">
            {subject.awaiting
              ? 'In a trance. Your next spoken words become their suggestion.'
              : 'In a trance, with no suggestion yet.'}
          </Box>
        )}
      </Box>
      {subject.reachable ? (
        <Stack>
          <Stack.Item grow>
            <Input
              fluid
              value={text}
              maxLength={1024}
              placeholder={
                subject.phrase ? 'Replace their suggestion' : 'Set a suggestion'
              }
              onChange={(value: string) => setText(value)}
              onEnter={suggest}
            />
          </Stack.Item>
          <Stack.Item>
            <Button icon="brain" disabled={!text.trim()} onClick={suggest}>
              Suggest
            </Button>
          </Stack.Item>
        </Stack>
      ) : (
        <Box color="label">Their mind is beyond your reach right now.</Box>
      )}
    </Section>
  );
};

export const SubjectsTab = (props: ModuleTabProps<SubjectsData>) => {
  const { module, moduleAct } = props;
  const { subjects } = module.data;

  return (
    <Section title="Subjects" fill scrollable>
      {!subjects.length && (
        <NoticeBox>
          You hold no one in a trance. Use your Hypnotic Gaze or Presence to
          take hold of a receptive mind.
        </NoticeBox>
      )}
      {subjects.map((subject) => (
        <SubjectEntry
          key={subject.ref}
          subject={subject}
          moduleAct={moduleAct}
        />
      ))}
    </Section>
  );
};
