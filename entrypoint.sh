#!/bin/sh -l

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
export APINAME="$LAMBDA_FUNC_NAME-API"
export OVERLAY_S3URL="s3://${BUCKET_NAME}/${LAMBDA_FUNC_NAME}/lambda-deploy.tgz"


rm -f lambda-deploy.zip
rm -f lambda-deploy-overlay.tgz
# Move to src directory 
cd src

echo 
echo "***************************"
echo "*****NPM INSTALL***********"
echo "***************************"

# npm install node modules
if npm install
then 
    echo "$(tput setaf 2)npm successfully installed$(tput sgr 0)"
else
    echo "$(tput setaf 2)**********ERROR***********$(tput sgr 0)"
fi

# zip project contents
zip -r ../lambda-deploy.zip *

# Move back to main project
cd ..

# Create a tarball of the entire project structure
tar -czf lambda-deploy-overlay.tgz ./

# Upload tar to AWS S3
aws s3 cp --acl public-read lambda-deploy-overlay.tgz "$OVERLAY_S3URL"

# Validate Cloudformation template
aws cloudformation validate-template \
    --template-body file://template.yaml

# Package template
aws cloudformation package \
   --template-file template.yaml \
   --output-template-file packaged.yaml \
   --s3-bucket "${BUCKET_NAME}" 

# Deploy stack
if  aws cloudformation deploy \
        --stack-name ${LAMBDA_FUNC_NAME} \
        --template-file packaged.yaml \
        --capabilities CAPABILITY_IAM \
        --region ${AWS_DEFAULT_REGION} \
        --parameter-overrides LambdaFuncName=${LAMBDA_FUNC_NAME} \
            LambdaRuntime=${LAMBDA_RUNTIME} \
            LambdaHandler=${LAMBDA_HANDLER} \
            LambdaMemory=${LAMBDA_MEMORY} \
            LambdaTimeout=${LAMBDA_TIMEOUT} 
    then 
        exit 0
    else
        exit 1
fi

    
exit 0 