import { useState } from 'react';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
  TextArea,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type TeamType = {
  id: string;
  name: string;
  desc: string;
};

type Role = {
  id: string;
  name: string;
  desc: string;
  total: number;
  taken: number;
};

type Member = {
  ckey: string;
  self: BooleanLike;
  admin: BooleanLike;
  role: string | null;
  ready: BooleanLike;
  name?: string;
  status?: string;
  removed?: BooleanLike;
};

type Data = {
  types: TeamType[];
  role_max: number;
  mission_max: number;
  stage: 'setup' | 'locked' | 'gathering' | 'active';
  is_admin: BooleanLike;
  can_control: BooleanLike;
  team_type: string | null;
  team_name: string | null;
  mission: string | null;
  roles: Role[];
  members: Member[];
  offer_admins?: BooleanLike;
  offer_ghosts?: BooleanLike;
  caller?: string | null;
  reason?: string | null;
};

export const ResponseTeamPanel = (props) => {
  const { data } = useBackend<Data>();
  return (
    <Window title="Emergency Response" width={560} height={640}>
      <Window.Content scrollable>
        {data.stage === 'setup' && <SetupStage />}
        {data.stage === 'locked' && <LockedStage />}
        {data.stage === 'gathering' && <GatheringStage />}
        {data.stage === 'active' && <ActiveStage />}
      </Window.Content>
    </Window>
  );
};

const roleName = (roles: Role[], id: string | null) =>
  roles.find((role) => role.id === id)?.name || 'None';

const TeamSummary = () => {
  const { data } = useBackend<Data>();
  return (
    <Section title={data.team_name || 'Response Team'}>
      <LabeledList>
        {!!data.caller && (
          <LabeledList.Item label="Called By">{data.caller}</LabeledList.Item>
        )}
        {!!data.reason && (
          <LabeledList.Item label="Reason">
            <Box preserveWhitespace>{data.reason}</Box>
          </LabeledList.Item>
        )}
        <LabeledList.Item label="Mission">
          <Box preserveWhitespace>{data.mission || 'None given.'}</Box>
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const SetupStage = () => {
  const { act, data } = useBackend<Data>();
  const [mission, setMission] = useState(data.mission || '');
  const total = data.roles.reduce((sum, role) => sum + role.total, 0);
  return (
    <>
      <Section title="Response Team Type">
        <Stack wrap>
          {data.types.map((type) => (
            <Stack.Item key={type.id} mb={0.5}>
              <Button
                selected={data.team_type === type.id}
                tooltip={type.desc}
                onClick={() => act('select_type', { type: type.id })}
              >
                {type.name}
                {data.team_type === type.id && ' (Selected)'}
              </Button>
            </Stack.Item>
          ))}
        </Stack>
      </Section>
      {!!data.team_type && (
        <Section title="Roles">
          <LabeledList>
            {data.roles.map((role) => (
              <LabeledList.Item
                key={role.id}
                label={role.name}
                buttons={
                  <>
                    <Button
                      icon="minus"
                      disabled={role.total <= 0}
                      onClick={() =>
                        act('set_slots', {
                          role: role.id,
                          amount: role.total - 1,
                        })
                      }
                    />
                    <Box inline width={2} textAlign="center" bold>
                      {role.total}
                    </Box>
                    <Button
                      icon="plus"
                      disabled={role.total >= data.role_max}
                      onClick={() =>
                        act('set_slots', {
                          role: role.id,
                          amount: role.total + 1,
                        })
                      }
                    />
                  </>
                }
              >
                <Box color="label">{role.desc}</Box>
              </LabeledList.Item>
            ))}
          </LabeledList>
        </Section>
      )}
      <Section title="Offer To">
        <Button.Checkbox
          checked={data.offer_admins}
          onClick={() => act('toggle_admins')}
        >
          Offer to Admins
        </Button.Checkbox>
        <Button.Checkbox
          checked={data.offer_ghosts}
          onClick={() => act('toggle_ghosts')}
        >
          Offer to Ghosts
        </Button.Checkbox>
      </Section>
      <Section title="Mission Instructions">
        <TextArea
          fluid
          height="120px"
          maxLength={data.mission_max}
          value={mission}
          onChange={(value: string) => setMission(value)}
        />
      </Section>
      <Button
        fluid
        icon="lock"
        textAlign="center"
        disabled={
          !data.team_type ||
          !total ||
          (!data.offer_admins && !data.offer_ghosts)
        }
        onClick={() => act('confirm', { mission })}
      >
        Confirm Response Team
      </Button>
    </>
  );
};

/** Roles the team was given at least one slot for */
const fieldedRoles = (roles: Role[]) => roles.filter((role) => role.total > 0);

type Action = { label: string; icon: string; action: string };

/** Full-width cancel (red) and go (green) buttons along the bottom of a stage */
const ActionPair = (props: {
  cancel: Action;
  go: Action;
  disabled?: boolean;
}) => {
  const { act } = useBackend<Data>();
  return (
    <Stack>
      {[props.cancel, props.go].map((item, index) => (
        <Stack.Item grow key={item.action}>
          <Button
            fluid
            color={index ? 'good' : 'bad'}
            icon={item.icon}
            textAlign="center"
            disabled={props.disabled}
            onClick={() => act(item.action)}
          >
            {item.label}
          </Button>
        </Stack.Item>
      ))}
    </Stack>
  );
};

const RoleTotals = () => {
  const { data } = useBackend<Data>();
  return (
    <Section title="Roles">
      <LabeledList>
        {fieldedRoles(data.roles).map((role) => (
          <LabeledList.Item key={role.id} label={role.name}>
            {role.total - role.taken} open of {role.total}
          </LabeledList.Item>
        ))}
      </LabeledList>
    </Section>
  );
};

const LockedStage = () => (
  <>
    <TeamSummary />
    <RoleTotals />
    <ActionPair
      cancel={{
        label: 'Cancel Response',
        icon: 'times',
        action: 'cancel_call',
      }}
      go={{ label: 'Call for Response', icon: 'bullhorn', action: 'call' }}
    />
  </>
);

const AdminTag = (props: { admin: BooleanLike }) =>
  props.admin ? (
    <Box inline ml={1} px={0.5} backgroundColor="purple" bold>
      ADMIN
    </Box>
  ) : null;

const VolunteerControls = (props: { self: Member }) => {
  const { act, data } = useBackend<Data>();
  const { self } = props;
  return (
    <Section title="Choose Your Role">
      <Stack vertical>
        {fieldedRoles(data.roles).map((role) => {
          const mine = self.role === role.id;
          return (
            <Stack.Item key={role.id}>
              <Button
                fluid
                selected={mine}
                disabled={!mine && role.taken >= role.total}
                tooltip={role.desc}
                onClick={() => act('pick_role', { role: role.id })}
              >
                {role.name} ({role.total - role.taken}/{role.total} open)
                {mine && ' (Selected)'}
              </Button>
            </Stack.Item>
          );
        })}
        <Stack.Item mt={1}>
          <Stack align="center">
            <Stack.Item grow color="label">
              {!self.role
                ? 'Pick a role above.'
                : self.ready
                  ? 'You will deploy when the team is dispatched.'
                  : 'Tick Ready to be included when the team is dispatched.'}
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={self.ready}
                color={self.ready ? 'good' : 'default'}
                disabled={!self.role}
                tooltip="Only ready responders are sent when the team is dispatched."
                onClick={() => act('ready')}
              >
                Ready
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button icon="sign-out-alt" onClick={() => act('withdraw')}>
                Withdraw
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const GatheringStage = () => {
  const { act, data } = useBackend<Data>();
  const self = data.members.find((member) => member.self);
  return (
    <>
      <TeamSummary />
      {!!self && <VolunteerControls self={self} />}
      {!self && <RoleTotals />}
      <Section
        title={`Queued Responders (${data.members.length})`}
        buttons={
          !!data.is_admin && (
            <Button
              icon="redo"
              disabled={!data.can_control}
              tooltip="Ask everyone eligible who isn't queued, kicked or already being asked."
              onClick={() => act('reoffer')}
            >
              Offer Again
            </Button>
          )
        }
      >
        {data.members.length === 0 && (
          <NoticeBox>Nobody has answered the call yet.</NoticeBox>
        )}
        <Table>
          {data.members.map((member, index) => (
            <Table.Row key={index} className="candystripe">
              <Table.Cell bold={!!member.self}>
                {member.ckey}
                <AdminTag admin={member.admin} />
              </Table.Cell>
              <Table.Cell>{roleName(data.roles, member.role)}</Table.Cell>
              <Table.Cell color={member.ready ? 'good' : 'average'}>
                {member.ready ? 'Ready' : 'Waiting'}
              </Table.Cell>
              {!!data.is_admin && (
                <Table.Cell collapsing>
                  <Button
                    color="bad"
                    icon="user-times"
                    disabled={!data.can_control}
                    onClick={() => act('kick', { ckey: member.ckey })}
                  >
                    Kick
                  </Button>
                </Table.Cell>
              )}
            </Table.Row>
          ))}
        </Table>
      </Section>
      {!!data.is_admin && (
        <ActionPair
          disabled={!data.can_control}
          cancel={{
            label: 'Cancel Team',
            icon: 'times',
            action: 'cancel_team',
          }}
          go={{ label: 'Dispatch Team', icon: 'flag', action: 'dispatch' }}
        />
      )}
    </>
  );
};

const statusColor = (status?: string) => {
  switch (status) {
    case 'Alive':
      return 'good';
    case 'Dead':
      return 'bad';
    default:
      return 'grey';
  }
};

const ActiveStage = () => {
  const { act, data } = useBackend<Data>();
  return (
    <>
      <NoticeBox success>Response is Active</NoticeBox>
      <TeamSummary />
      <Section
        title="Deployed Members"
        buttons={
          <Button icon="bullhorn" onClick={() => act('broadcast')}>
            Broadcast to Team
          </Button>
        }
      >
        <Table>
          <Table.Row header>
            <Table.Cell>Name</Table.Cell>
            <Table.Cell>Role</Table.Cell>
            <Table.Cell>Status</Table.Cell>
            <Table.Cell>Ckey</Table.Cell>
            <Table.Cell />
          </Table.Row>
          {data.members.map((member) => (
            <Table.Row key={member.ckey} className="candystripe">
              <Table.Cell>{member.name || 'Unknown'}</Table.Cell>
              <Table.Cell>{roleName(data.roles, member.role)}</Table.Cell>
              <Table.Cell color={statusColor(member.status)}>
                {member.status}
              </Table.Cell>
              <Table.Cell>
                {member.ckey}
                <AdminTag admin={member.admin} />
              </Table.Cell>
              <Table.Cell collapsing>
                <Button
                  icon="user"
                  tooltip="Player Panel"
                  disabled={!!member.removed}
                  onClick={() => act('pp', { ckey: member.ckey })}
                />
                <Button
                  icon="eye"
                  tooltip="Follow"
                  disabled={!!member.removed}
                  onClick={() => act('follow', { ckey: member.ckey })}
                />
                <Button
                  icon="comment"
                  tooltip="Message"
                  disabled={!!member.removed}
                  onClick={() => act('message', { ckey: member.ckey })}
                />
                <Button
                  color="bad"
                  icon="trash"
                  tooltip="Remove"
                  disabled={!!member.removed}
                  onClick={() => act('remove', { ckey: member.ckey })}
                />
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      </Section>
      <Button.Confirm
        fluid
        color="bad"
        icon="power-off"
        textAlign="center"
        confirmIcon="exclamation-triangle"
        confirmContent="Click again to delete every responder's body and gear"
        onClick={() => act('end')}
      >
        End Deployment
      </Button.Confirm>
    </>
  );
};
