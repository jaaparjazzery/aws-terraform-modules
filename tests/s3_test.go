package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestS3BucketCreation(t *testing.T) {
	t.Parallel()

	bucketName := fmt.Sprintf("test-bucket-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/s3",
		Vars: map[string]interface{}{
			"bucket_name": bucketName,
			"environment": "test",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	bucketID := terraform.Output(t, terraformOptions, "bucket_id")
	assert.Equal(t, bucketName, bucketID)

	bucketArn := terraform.Output(t, terraformOptions, "bucket_arn")
	assert.Contains(t, bucketArn, bucketName)

	region := "us-east-1"
	s3Client := createS3Client(t, region)

	bucket := getBucket(t, s3Client, bucketName)
	assert.NotNil(t, bucket)
}

func TestS3BucketVersioning(t *testing.T) {
	t.Parallel()

	bucketName := fmt.Sprintf("test-bucket-versioning-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/s3",
		Vars: map[string]interface{}{
			"bucket_name":        bucketName,
			"enable_versioning":  true,
			"environment":        "test",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	bucketID := terraform.Output(t, terraformOptions, "bucket_id")
	region := "us-east-1"
	s3Client := createS3Client(t, region)

	versioningStatus := getBucketVersioning(t, s3Client, bucketID)
	assert.Equal(t, "Enabled", versioningStatus)
}

func TestS3BucketEncryption(t *testing.T) {
	t.Parallel()

	bucketName := fmt.Sprintf("test-bucket-encryption-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/s3",
		Vars: map[string]interface{}{
			"bucket_name":       bucketName,
			"enable_encryption": true,
			"environment":       "test",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	bucketID := terraform.Output(t, terraformOptions, "bucket_id")
	region := "us-east-1"
	s3Client := createS3Client(t, region)

	encryption := getBucketEncryption(t, s3Client, bucketID)
	assert.NotNil(t, encryption)
	assert.NotEmpty(t, encryption.Rules)
}

func TestS3BucketLifecyclePolicy(t *testing.T) {
	t.Parallel()

	bucketName := fmt.Sprintf("test-bucket-lifecycle-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/s3",
		Vars: map[string]interface{}{
			"bucket_name":            bucketName,
			"enable_lifecycle_rules": true,
			"transition_days":        30,
			"expiration_days":        90,
			"environment":            "test",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	bucketID := terraform.Output(t, terraformOptions, "bucket_id")
	region := "us-east-1"
	s3Client := createS3Client(t, region)

	lifecycle := getBucketLifecycle(t, s3Client, bucketID)
	assert.NotNil(t, lifecycle)
	assert.NotEmpty(t, lifecycle.Rules)
}

func TestS3BucketPublicAccessBlock(t *testing.T) {
	t.Parallel()

	bucketName := fmt.Sprintf("test-bucket-public-block-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/s3",
		Vars: map[string]interface{}{
			"bucket_name":                bucketName,
			"block_public_acls":          true,
			"block_public_policy":        true,
			"ignore_public_acls":         true,
			"restrict_public_buckets":    true,
			"environment":                "test",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	bucketID := terraform.Output(t, terraformOptions, "bucket_id")
	region := "us-east-1"
	s3Client := createS3Client(t, region)

	publicAccessBlock := getBucketPublicAccessBlock(t, s3Client, bucketID)
	assert.True(t, *publicAccessBlock.BlockPublicAcls)
	assert.True(t, *publicAccessBlock.BlockPublicPolicy)
	assert.True(t, *publicAccessBlock.IgnorePublicAcls)
	assert.True(t, *publicAccessBlock.RestrictPublicBuckets)
}

func TestS3BucketTags(t *testing.T) {
	t.Parallel()

	bucketName := fmt.Sprintf("test-bucket-tags-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/s3",
		Vars: map[string]interface{}{
			"bucket_name": bucketName,
			"environment": "test",
			"tags": map[string]string{
				"Project": "Infrastructure-Test",
				"Owner":   "DevOps-Team",
			},
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	bucketID := terraform.Output(t, terraformOptions, "bucket_id")
	region := "us-east-1"
	s3Client := createS3Client(t, region)

	tags := getBucketTags(t, s3Client, bucketID)
	assert.Equal(t, "test", tags["Environment"])
	assert.Equal(t, "Infrastructure-Test", tags["Project"])
	assert.Equal(t, "DevOps-Team", tags["Owner"])
}

func createS3Client(t *testing.T, region string) *s3.S3 {
	sess := createAWSSession(t, region)
	return s3.New(sess)
}

func getBucket(t *testing.T, client *s3.S3, bucketName string) *s3.Bucket {
	input := &s3.ListBucketsInput{}
	result, err := client.ListBuckets(input)
	assert.NoError(t, err)

	for _, bucket := range result.Buckets {
		if *bucket.Name == bucketName {
			return bucket
		}
	}

	t.Fatalf("Bucket %s not found", bucketName)
	return nil
}

func getBucketVersioning(t *testing.T, client *s3.S3, bucketName string) string {
	input := &s3.GetBucketVersioningInput{
		Bucket: aws.String(bucketName),
	}

	result, err := client.GetBucketVersioning(input)
	assert.NoError(t, err)

	if result.Status == nil {
		return "Disabled"
	}
	return *result.Status
}

func getBucketEncryption(t *testing.T, client *s3.S3, bucketName string) *s3.ServerSideEncryptionConfiguration {
	input := &s3.GetBucketEncryptionInput{
		Bucket: aws.String(bucketName),
	}

	result, err := client.GetBucketEncryption(input)
	if err != nil {
		return nil
	}

	return result.ServerSideEncryptionConfiguration
}

func getBucketLifecycle(t *testing.T, client *s3.S3, bucketName string) *s3.GetBucketLifecycleConfigurationOutput {
	input := &s3.GetBucketLifecycleConfigurationInput{
		Bucket: aws.String(bucketName),
	}

	result, err := client.GetBucketLifecycleConfiguration(input)
	if err != nil {
		return nil
	}

	return result
}

func getBucketPublicAccessBlock(t *testing.T, client *s3.S3, bucketName string) *s3.PublicAccessBlockConfiguration {
	input := &s3.GetPublicAccessBlockInput{
		Bucket: aws.String(bucketName),
	}

	result, err := client.GetPublicAccessBlock(input)
	assert.NoError(t, err)

	return result.PublicAccessBlockConfiguration
}

func getBucketTags(t *testing.T, client *s3.S3, bucketName string) map[string]string {
	input := &s3.GetBucketTaggingInput{
		Bucket: aws.String(bucketName),
	}

	result, err := client.GetBucketTagging(input)
	assert.NoError(t, err)

	tags := make(map[string]string)
	for _, tag := range result.TagSet {
		if tag.Key != nil && tag.Value != nil {
			tags[*tag.Key] = *tag.Value
		}
	}

	return tags
}
