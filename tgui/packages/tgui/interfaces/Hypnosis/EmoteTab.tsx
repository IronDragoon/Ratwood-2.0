import { useEffect, useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  LabeledList,
  NoticeBox,
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
  /** Our subjects who can receive right now */
  targets: Target[];
  subjects_in_view: number;
  allowed_styles: string[];
  style: string;
  /** Rendered and sanitized server-side, exactly as it would be sent */
  preview_html: string | null;
};

/** How long typing must pause before asking the server for a preview */
const PREVIEW_DELAY_MS = 300;

const ALL_IN_VIEW = 'all_in_view';

export const EmoteTab = (props: ModuleTabProps<EmoteData>) => {
  const { module, styles, moduleAct } = props;
  const { act } = useBackend();
  const { targets, subjects_in_view, allowed_styles, style, preview_html } =
    module.data;
  const [message, setMessage] = useState('');
  const [target, setTarget] = useState(ALL_IN_VIEW);

  // Re-render the preview server-side once typing pauses or the style changes
  useEffect(() => {
    if (!message.trim()) {
      return;
    }
    const timer = setTimeout(
      () => moduleAct('preview', { message }),
      PREVIEW_DELAY_MS,
    );
    return () => clearTimeout(timer);
  }, [message, style]);

  const styleOptions = styles
    .filter((s) => allowed_styles.includes(s.id))
    .map((s) => ({ value: s.id, displayText: s.name }));
  const currentStyle = styles.find((s) => s.id === style);
  const allOption = {
    value: ALL_IN_VIEW,
    displayText: `All my subjects in view (${subjects_in_view})`,
  };
  const targetOptions = [
    allOption,
    ...targets.map((t) => ({ value: t.ref, displayText: t.name })),
  ];
  const selectedTarget =
    targetOptions.find((o) => o.value === target) || allOption;

  const send = () => {
    if (!message.trim()) {
      return;
    }
    moduleAct('send', { message, target: selectedTarget.value });
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
          {!targets.length && (
            <NoticeBox>
              No one is in your hold. Entrance someone with your Hypnotic Gaze
              or Presence first.
            </NoticeBox>
          )}
          <LabeledList>
            <LabeledList.Item label="Target">
              <Dropdown
                width="100%"
                selected={selectedTarget.displayText}
                options={targetOptions}
                onSelected={(value) => setTarget(value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Style">
              <Dropdown
                width="100%"
                selected={currentStyle?.name}
                options={styleOptions}
                onSelected={(value) => moduleAct('set_style', { style: value })}
              />
              <Box color="label" mt={0.5}>
                Saved, and used for everything you send, your gaze and
                suggestions included.
              </Box>
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
                {message.trim() && preview_html ? (
                  // eslint-disable-next-line react/no-danger -- html is encoded and rendered server-side
                  <span dangerouslySetInnerHTML={{ __html: preview_html }} />
                ) : (
                  <span className={currentStyle?.css_class}>
                    Your words, as they will appear.
                  </span>
                )}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Button
                fluid
                icon="eye"
                textAlign="center"
                disabled={!message.trim() || !targets.length}
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
