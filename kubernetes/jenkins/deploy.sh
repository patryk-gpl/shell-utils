#!/usr/bin/env bash

kubectl apply -f namespace.yaml
kubectl apply -f serviceAccount.yaml

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f volume.yaml
