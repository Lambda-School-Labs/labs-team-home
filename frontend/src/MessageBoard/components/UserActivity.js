import React from 'react';
import styled from 'styled-components';

const Container = styled.div`
	display: flex;
	flex-direction: row;
	justify-content: flex-end;
	align-items: center;
	height: 75px;
	width: 80%;
	border: 1px solid black;
	background-color: white;
	margin: 20px;
	padding: 20px;

	& p {
		margin: 0 10px;
	}

	& img {
		height: 50px;
		width: 50px;
	}
`;

const Info = styled.div`
	display: flex;
	flex-direction: column;
	justify-content: flex-end;
	text-align: right;
	padding: 0 20px;
	margin: 5px 10px;
`;

const Title = styled.p`
	font-weight: bold;
`;

export default function UserActivity(props) {
	if (props.message.__typename === 'Message') {
		return (
			<Container>
				<Info>
					<p>You posted a new message</p>
					<p>{props.message.updatedAt.toDateString()}</p>
					<Title>{props.message.title}</Title>
				</Info>
				<img
					src={props.message.user.avatar}
					alt="User avatar"
					height="50px"
					width="50px"
				/>
			</Container>
		);
	} else {
		return (
			<Container>
				<Info>
					<p>You posted a new comment</p>
					<p>{props.message.updatedAt.toDateString()}</p>
					<Title>{props.message.title}</Title>
				</Info>
				<img
					src={props.message.user.avatar}
					alt="User avatar"
					height="50px"
					width="50px"
				/>
			</Container>
		);
	}
}