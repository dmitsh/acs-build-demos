#!/bin/bash

rm -r $HOME/lib/azure-cli
rm $HOME/bin/az
sed -i "/\/lib\/azure-cli\/az.completion'/d" ~/.bashrc
