import React, { Component } from 'react';
import { Query } from 'react-apollo';
import styled from 'styled-components';
import * as query from '../../constants/queries';
import DocumentDetails from './DocumentDetails';
import { DropTarget } from 'react-dnd';
import Doc from './Doc';
import { compose } from 'react-apollo';
import { updateDocument } from '../mutations/documents';

const Container = styled.div`
	display: flex;
	flex-wrap: wrap;
	justify-content: center;
	background-color: #4a4550;
	min-width: 300px;
	min-height: 50px;
`;

// const Container2 = styled.div`
// 	display: flex;
// 	flex-wrap: wrap;
// 	justify-content: center;
// 	background-color: blue;
// 	min-width: 300px;
// 	min-height: 50px;
// 	width: 696px;
// `;

const IndividualDocument = styled.div`
	color: white;
	margin: 10px;
	padding: 10px;
	border: 2px solid white;
`;
const Error = styled.p`
	color: white;
`;

const FormDiv = styled.div`
	width: 92%;
	display: flex;
	flex-direction: row-reverse;
`;

const SortForm = styled.form`
	height: 50px;
	label {
		color: white;
		font-size: 20px;
	}
	select {
		margin-left: 10px;
	}
	option {
		height: 50px;
	}
`;

var folderId;

function collect(connect, monitor) {
	return {
		connectDropTarget: connect.dropTarget(),
		hovered: monitor.isOver(),
		document: monitor.getItem()
	};
}

class Documents extends Component {
	constructor(props) {
		super(props);
		this.state = {
			currentDocument: null,
			documentDetailOpen: false,
			sortOption: 'newest'
		};
	}

	toggleDocumentDetail = doc => {
		this.setState(prevState => ({
			documentDetailOpen: !prevState.documentDetailOpen,
			currentDocument: doc
		}));
	};

	sortChange = e => {
		this.setState({ sortOption: e.target.value });
	};

	updateDrop = id => {
		console.log('Staging DOC: ', id);
		console.log('DropArea ID: ', folderId);

		this.props.updateDocument({ id: id, folder: folderId });
		console.log('Document Update');
	};

	render() {
		// console.log('props: ', this.props);
		const { connectDropTarget, hovered } = this.props;
		const backgroundColor = hovered ? 'lightgray' : '';
		if (hovered) {
			folderId = 'null';
			console.log(folderId);
		}

		return connectDropTarget(
			<div>
				<Container style={{ background: backgroundColor }}>
					<FormDiv>
						<SortForm>
							<label>
								Folder Sort:
								<select
									value={this.state.sortOption}
									onChange={this.sortChange}
								>
									<option value="newest">Newest First</option>
									<option value="oldest">Oldest First</option>
								</select>
							</label>
						</SortForm>
					</FormDiv>
					{/* Find all the documents  */}
					<Query
						query={query.FIND_DOCUMENTS_BY_TEAM}
						variables={{ team: this.props.team._id }}
					>
						{({ loading, error, data: { findDocumentsByTeam } }) => {
							// if (networkStatus === 4) return "Refetching";
							if (loading) return <p>Loading...</p>;
							if (error) return console.error(error);
							if (findDocumentsByTeam && findDocumentsByTeam.length > 0) {
								switch (this.state.sortOption) {
									case 'newest':
										findDocumentsByTeam.sort((a, b) => {
											if (a.createdAt < b.createdAt) return 1;
											if (a.createdAt > b.createdAt) return -1;
											return 0;
										});
										break;
									case 'oldest':
										findDocumentsByTeam.sort((a, b) => {
											if (a.createdAt < b.createdAt) return -1;
											if (a.createdAt > b.createdAt) return 1;
											return 0;
										});
										break;
									default:
										break;
								}

								return findDocumentsByTeam
									.filter(doc => doc.folder === null)
									.map(doc => {
										return (
											<div
												onClick={() => this.toggleDocumentDetail(doc)}
												key={doc._id}
											>
												<Doc
													document={doc}
													handleDrop={id => this.updateDrop(id)}
												/>
											</div>
										);
									});
							} else {
								return <Error>No Documents Available For This Team</Error>;
							}
						}}
					</Query>
					{/* All the Modals */}
					<DocumentDetails
						open={this.state.documentDetailOpen}
						hideModal={() => this.toggleDocumentDetail(null)}
						document={this.state.currentDocument}
						currentUser={this.props.currentUser}
						team={this.props.team._id}
					/>
				</Container>
			</div>
		);
	}
}

export default compose(
	DropTarget('item', {}, collect),
	updateDocument
)(Documents);
