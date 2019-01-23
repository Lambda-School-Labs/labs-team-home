import gql from 'graphql-tag';
import * as f from './fragments';

export const FIND_TEAMS_BY_USER = gql`
	{
		findTeamsByUser {
			...FullTeam
		}
	}
	${f.FULL_TEAM}
`;

export const FIND_MESSAGES_BY_TEAM = gql`
	query findMessagesByTeam($team: ID!) {
		findMessagesByTeam(input: { team: $team }) {
			...FullMessage
		}
	}
	${f.FULL_MESSAGE}
`;

export const FIND_MESSAGE = gql`
	query findMessage($id: ID!) {
		findMessage(input: { id: $id }) {
			...FullMessage
		}
	}
	${f.FULL_MESSAGE}
`;

export const FIND_TAGS_BY_TEAM = gql`
	query findTagsByTeam($id: ID) {
		findTagsByTeam(input: { id: $id }) {
			...FullTag
		}
	}
	${f.FULL_TAG}
`;

export const FIND_COMMENTS_BY_MESSAGE = gql`
	query findMsgCommentsByMessage($message: ID!) {
		findMsgCommentsByMessage(input: { message: $message }) {
			...FullComment
		}
	}
	${f.FULL_COMMENT}
`;
