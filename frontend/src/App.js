import React, { Component } from 'react';
// import logo from './logo.svg';
import './App.css';
import LandingView from './LandingView/containers/LandingView';
import { Route } from 'react-router-dom';
import MessageBoard from './MessageBoard/components/MessageBoard';
import Dashboard from './DashboardView/containers/Dashboard';
import AuthRoute from './Auth/components/AuthRoute';
import ImageUpload from './ImageUpload/ImageUpload';

class App extends Component {
	render() {
		return (
			<div className="App">
				<Route exact path="/" component={LandingView} />
				<Route path="/home" component={MessageBoard} />
				{/* <AuthRoute path="/dashboard" component={Dashboard} /> */}
				<Route path="/upload" component={ImageUpload} />
			</div>
		);
	}
}

export default App;
