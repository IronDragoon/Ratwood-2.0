import { useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  LabeledList,
  Section,
  Stack,
  TextArea,
} from 'tgui-core/components';

import { useBackend } from '../../backend';
import type { ModuleTabProps } from './types';

type Target = {
  ref: string;
  name: string;
};

type EmoteData = {
  targets: Target[];
  receptive_count: number;
  allowed_styles: string[];
  style: string;
};

type Mode = 'subtle' | 'open';

const AREA_TARGETS = [
  { value: 'area_all', displayText: 'Everyone receptive nearby' },
  { value: 'area_adjacent', displayText: 'Within 1 tile' },
  { value: 'area_same_tile', displayText: 'Same tile' },
];

export const EmoteTab = (props: ModuleTabProps<EmoteData>) => {
  const { module, styles, moduleAct } = props;
  const { act } = useBackend();
  const { targets, receptive_count, allowed_styles, style } = module.data;
  const [message, setMessage] = useState('');
  const [mode, setMode] = useState<Mode>('subtle');
  const [target, setTarget] = useState('area_all');

  const styleOptions = styles
    .filter((s) => allowed_styles.includes(s.id))
    .map((s) => ({ value: s.id, displayText: s.name }));
  const currentStyle = styles.find((s) => s.id === style);
  const targetOptions = [
    ...AREA_TARGETS,
    ...targets.map((t) => ({ value: t.ref, displayText: t.name })),
  ];
  const selectedTarget =
    targetOptions.find((o) => o.value === target) || AREA_TARGETS[0];

  const send = () => {
    if (!message.trim()) {
      return;
    }
    moduleAct('send', { mode, message, target: selectedTarget.value });
    setMessage('');
  };

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section
          title="Delivery"
          buttons={
            <Button icon="sync" onClick={() => act('refresh_targets')}>
              Refresh
            </Button>
          }
        >
          <LabeledList>
            <LabeledList.Item label="Mode">
              <Button
                selected={mode === 'subtle'}
                onClick={() => setMode('subtle')}
              >
                Subtle
              </Button>
              <Button
                selected={mode === 'open'}
                onClick={() => setMode('open')}
              >
                Open
              </Button>
            </LabeledList.Item>
            {mode === 'subtle' ? (
              <LabeledList.Item label="Target">
                <Dropdown
                  width="100%"
                  selected={selectedTarget.displayText}
                  options={targetOptions}
                  onSelected={(value) => setTarget(value)}
                />
              </LabeledList.Item>
            ) : (
              <LabeledList.Item label="Reach">
                {receptive_count} receptive{' '}
                {receptive_count === 1 ? 'mind' : 'minds'} in view
              </LabeledList.Item>
            )}
            <LabeledList.Item label="Style">
              <Dropdown
                width="100%"
                selected={currentStyle?.name}
                options={styleOptions}
                onSelected={(value) => moduleAct('set_style', { style: value })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section title="Message" fill>
          <Stack vertical fill>
            <Stack.Item grow>
              <TextArea
                fluid
                height="100%"
                value={message}
                onChange={(value: string) => setMessage(value)}
                placeholder="What does your character hypnotically do?"
              />
            </Stack.Item>
            <Stack.Item>
              <Box color="label" mb={0.5}>
                Preview
              </Box>
              <Box>
                <span className={currentStyle?.css_class}>
                  {message || 'Your words, as they will appear.'}
                </span>
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Button
                fluid
                icon="eye"
                textAlign="center"
                disabled={!message.trim()}
                onClick={send}
              >
                Send
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
