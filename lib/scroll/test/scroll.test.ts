import {Match, Template} from "aws-cdk-lib/assertions";
import * as cdk from "aws-cdk-lib";
import * as dotenv from 'dotenv';

dotenv.config({path: './test/.env-test'});
import * as config from "../lib/config/scrollConfig";
import {ScrollSingleNodeStack} from "../lib/single-node-stack";

describe("ScrollSingleNodeStack", () => {
  let app: cdk.App;
  let scrollSingleNodeStack: ScrollSingleNodeStack;
  let template: Template;
  beforeAll(() => {
    app = new cdk.App();

    // Create the ScrollSingleNodeStack.
    scrollSingleNodeStack = new ScrollSingleNodeStack(app, "eth-sync-node", {
      stackName: `eth-sync-node-${config.baseConfig.accountId}`,
      env: {account: config.baseConfig.accountId, region: config.baseConfig.region},

      instanceType: config.baseNodeConfig.instanceType,
      instanceCpuType: config.baseNodeConfig.instanceCpuType,
      scrollCluster: config.baseNodeConfig.scrollCluster,
      scrollVersion: config.baseNodeConfig.scrollVersion,
      nodeConfiguration: config.baseNodeConfig.nodeConfiguration,
      dataVolume: config.baseNodeConfig.dataVolume,
      scrollNodeIdentitySecretARN: config.baseNodeConfig.scrollNodeIdentitySecretARN,
      voteAccountSecretARN: config.baseNodeConfig.voteAccountSecretARN,
      authorizedWithdrawerAccountSecretARN: config.baseNodeConfig.authorizedWithdrawerAccountSecretARN,
      registrationTransactionFundingAccountSecretARN: config.baseNodeConfig.registrationTransactionFundingAccountSecretARN,
      l1Endpoint: config.baseNodeConfig.l1Endpoint
    });

    template = Template.fromStack(scrollSingleNodeStack);
  });

  test("Check Security Group", () => {
    // Has EC2 instance security group.
    template.hasResourceProperties("AWS::EC2::SecurityGroup", {
      GroupDescription: Match.anyValue(),
      VpcId: Match.anyValue(),
      SecurityGroupEgress: [
        {
          "CidrIp": "0.0.0.0/0",
          "Description": "Allow all outbound traffic by default",
          "IpProtocol": "-1"
        }
      ],
      SecurityGroupIngress: [
        {
          "CidrIp": "0.0.0.0/0",
          "Description": "P2P protocols",
          "FromPort": 8545,
          "IpProtocol": "tcp",
          "ToPort": 8545
        },
        {
          "CidrIp": "0.0.0.0/0",
          "Description": "P2P protocols",
          "FromPort": 8545,
          "IpProtocol": "udp",
          "ToPort": 8545
        }
      ]
    })
  });


  test("Check EC2 Settings", () => {
    // Has EC2 instance with node configuration
    template.hasResourceProperties("AWS::EC2::Instance", {
      AvailabilityZone: Match.anyValue(),
      UserData: Match.anyValue(),
      BlockDeviceMappings: [
        {
          DeviceName: "/dev/sda1",
          Ebs: {
            DeleteOnTermination: true,
            Encrypted: true,
            Iops: 3000,
            VolumeSize: 46,
            VolumeType: "gp3"
          }
        }
      ],
      IamInstanceProfile: Match.anyValue(),
      ImageId: Match.anyValue(),
      InstanceType: "t3.2xlarge",
      Monitoring: true,
      PropagateTagsToVolumeOnCreation: true,
      SecurityGroupIds: Match.anyValue(),
      SubnetId: Match.anyValue(),
    });

    // // Has EBS data volume.
    template.hasResourceProperties("AWS::EC2::Volume", {
      AvailabilityZone: Match.anyValue(),
      Encrypted: true,
      Iops: 3000,
      MultiAttachEnabled: false,
      Size: 1000,
      Throughput: 700,
      VolumeType: "gp3"
    })

    // Has EBS data volume attachment.
    template.hasResourceProperties("AWS::EC2::VolumeAttachment", {
      Device: "/dev/sdf",
      InstanceId: Match.anyValue(),
      VolumeId: Match.anyValue(),
    })
  });

  test("Check CloudWatch Dashboard", () => {
    // Has CloudWatch dashboard.
    template.hasResourceProperties("AWS::CloudWatch::Dashboard", {
      DashboardBody: Match.anyValue(),
      DashboardName: `eth-sync-node-${config.baseConfig.accountId}`
    })
  });
});
