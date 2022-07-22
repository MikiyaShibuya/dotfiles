#!/bin/bash
service ssh start
su $ENTRY_USER -c "nvim -qa"
su $ENTRY_USER -c /bin/bash

