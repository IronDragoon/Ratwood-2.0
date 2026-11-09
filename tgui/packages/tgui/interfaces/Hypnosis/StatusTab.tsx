import { NoticeBox, Section } from 'tgui-core/components';

import type { ModuleTabProps } from './types';

type StatusData = {
  receptive: boolean;
  /** Whether a hypnotic gaze or presence has put us in a trance */
  trance: boolean;
  /** The suggestion's phrase, once one has been captured */
  phrase: string | null;
};

export const StatusTab = (props: ModuleTabProps<StatusData>) => {
  const { receptive, trance, phrase } = props.module.data;

  return (
    <Section title="Status" fill>
      {receptive ? (
        <NoticeBox info>Your mind is open to hypnotic suggestion.</NoticeBox>
      ) : (
        <NoticeBox>Your mind cannot be reached right now.</NoticeBox>
      )}
      {!!phrase && (
        <NoticeBox color="purple">
          A suggestion lingers in your mind: {phrase}
        </NoticeBox>
      )}
      {trance && !phrase && (
        <NoticeBox color="purple">
          Your mind is in a trance, awaiting a suggestion.
        </NoticeBox>
      )}
      {!trance && <NoticeBox>You are not under any suggestion.</NoticeBox>}
    </Section>
  );
};
