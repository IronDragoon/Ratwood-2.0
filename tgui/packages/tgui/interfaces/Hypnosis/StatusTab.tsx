import { NoticeBox, Section } from 'tgui-core/components';

import type { ModuleTabProps } from './types';

type StatusData = {
  receptive: boolean;
};

export const StatusTab = (props: ModuleTabProps<StatusData>) => {
  const { receptive } = props.module.data;

  return (
    <Section title="Status" fill>
      {receptive ? (
        <NoticeBox info>Your mind is open to hypnotic suggestion.</NoticeBox>
      ) : (
        <NoticeBox>Your mind cannot be reached right now.</NoticeBox>
      )}
    </Section>
  );
};
