# Tokenized Decentralized Fitness Coaching Networks

A blockchain-based fitness coaching platform built on the Stacks blockchain using Clarity smart contracts. This decentralized network connects fitness enthusiasts with professional trainers while providing comprehensive health and wellness tracking.

## Overview

The platform consists of five core smart contracts that work together to create a complete fitness coaching ecosystem:

### Core Contracts

1. **Goal Setting Contract** (`goal-setting.clar`)
    - Establishes personalized health and fitness objectives
    - Tracks goal progress and completion
    - Manages goal categories and target dates

2. **Progress Monitoring Contract** (`progress-monitoring.clar`)
    - Tracks workout completion and physical improvements
    - Records fitness metrics and measurements
    - Maintains workout history and achievements

3. **Nutrition Guidance Contract** (`nutrition-guidance.clar`)
    - Provides dietary recommendations and meal planning
    - Tracks nutritional intake and preferences
    - Manages meal plans and dietary restrictions

4. **Trainer Matching Contract** (`trainer-matching.clar`)
    - Connects clients with appropriate fitness professionals
    - Manages trainer profiles and specializations
    - Handles client-trainer relationships and ratings

5. **Motivation Tracking Contract** (`motivation-tracking.clar`)
    - Maintains engagement and accountability systems
    - Tracks streaks, rewards, and achievements
    - Manages motivation tokens and incentives

## Features

- **Decentralized Architecture**: No single point of failure
- **Token-Based Incentives**: Reward system for achieving goals
- **Privacy-Focused**: User data stored on blockchain with privacy controls
- **Trainer Verification**: Decentralized trainer credentialing system
- **Progress Analytics**: Comprehensive fitness and nutrition tracking
- **Community Driven**: Peer-to-peer motivation and support

## Technology Stack

- **Blockchain**: Stacks (Bitcoin Layer 2)
- **Smart Contracts**: Clarity
- **Testing**: Vitest
- **Token Standard**: SIP-010 (Stacks Improvement Proposal)

## Getting Started

### Prerequisites

- Clarinet CLI
- Node.js and npm
- Stacks wallet for testing

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts: \`clarinet deploy\`

### Usage

Each contract can be interacted with independently:

- Set fitness goals using the goal-setting contract
- Log workouts and progress via progress-monitoring
- Get nutrition recommendations from nutrition-guidance
- Find trainers through trainer-matching
- Track motivation and earn rewards with motivation-tracking

## Contract Architecture

### Data Structures

- **Users**: Principal-based identification
- **Goals**: Structured fitness objectives with deadlines
- **Workouts**: Exercise sessions with metrics
- **Meals**: Nutritional data and meal planning
- **Trainers**: Professional profiles with specializations
- **Rewards**: Token-based incentive system

### Security Features

- Principal-based access control
- Input validation and sanitization
- Overflow protection for numeric operations
- State consistency checks

## Testing

Comprehensive test suite covering:
- Contract deployment and initialization
- User registration and profile management
- Goal setting and progress tracking
- Trainer-client matching algorithms
- Token distribution and rewards
- Edge cases and error handling

Run tests with: \`npm test\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For questions and support, please open an issue in the repository.
