import { Box, Button, NoticeBox, Section } from 'tgui-core/components';

import type { ModuleTabProps } from './types';

type LogEntry = {
  sender: string;
  time: string;
  /** Rendered and sanitized server-side */
  html: string;
};

type ReceivedData = {
  log: LogEntry[];
};

export const ReceivedTab = (props: ModuleTabProps<ReceivedData>) => {
  const { module, moduleAct } = props;
  const log = [...module.data.log].reverse();

  return (
    <Section
      title="Received"
      fill
      scrollable
      buttons={
        <Button
          icon="trash"
          disabled={!log.length}
          onClick={() => moduleAct('clear')}
        >
          Clear
        </Button>
      }
    >
      {!log.length && <NoticeBox>No hypnotic messages received yet.</NoticeBox>}
      {log.map((entry, i) => (
        <Box key={i} mb={1}>
          <Box inline color="label" mr={1}>
            [{entry.time}]
          </Box>
          {/* eslint-disable-next-line react/no-danger -- html is encoded and rendered server-side */}
          <span dangerouslySetInnerHTML={{ __html: entry.html }} />
        </Box>
      ))}
    </Section>
  );
};
