#!/bin/sh
#-------------------------------------------------------------------------------
# A convenient way to run all the integration tests for client -> server interaction
#
# It supposes that DIRAC client is installed in $CLIENTINSTALLDIR
# and that there's a DIRAC server running with all the services running.
#-------------------------------------------------------------------------------

echo -e '****************************************'
echo -e '********' "client -> server tests" '********\n'



#-------------------------------------------------------------------------------#
echo -e '***' $(date -u) "**** Accounting TESTS ****\n"
python -m pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/AccountingSystem/Test_DataStoreClient.py >> clientTestOutputs.txt 2>&1
python -m pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/AccountingSystem/Test_ReportsClient.py >> clientTestOutputs.txt 2>&1


#-------------------------------------------------------------------------------#
echo -e '***' $(date -u)  "**** RMS TESTS ****\n"

echo -e '***' $(date -u)  "Getting a non privileged user\n" >> clientTestOutputs.txt 2>&1
dirac-proxy-init -C $SERVERINSTALLDIR/user/client.pem -K $SERVERINSTALLDIR/user/client.key $DEBUG >> clientTestOutputs.txt 2>&1

echo -e '***' $(date -u)  "Starting RMS Client test as a non privileged user\n" >> clientTestOutputs.txt 2>&1
python -m pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/RequestManagementSystem/Test_Client_Req.py >> clientTestOutputs.txt 2>&1

echo -e '***' $(date -u)  "getting the prod role again\n" >> clientTestOutputs.txt 2>&1
dirac-proxy-init -g prod -C $SERVERINSTALLDIR/user/client.pem -K $SERVERINSTALLDIR/user/client.key $DEBUG >> clientTestOutputs.txt 2>&1
echo -e '***' $(date -u)  "Starting RMS Client test as an admin user\n" >> clientTestOutputs.txt 2>&1
python -m pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/RequestManagementSystem/Test_Client_Req.py >> clientTestOutputs.txt 2>&1


#-------------------------------------------------------------------------------#
echo -e '***' $(date -u)  "**** RSS TESTS ****\n"
python -m pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/ResourceStatusSystem/Test_ResourceManagement.py >> clientTestOutputs.txt 2>&1
python -m pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/ResourceStatusSystem/Test_ResourceStatus.py >> clientTestOutputs.txt 2>&1
python -m pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/ResourceStatusSystem/Test_SiteStatus.py >> clientTestOutputs.txt 2>&1
python -m pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/ResourceStatusSystem/Test_Publisher.py >> clientTestOutputs.txt 2>&1


#-------------------------------------------------------------------------------#
echo -e '***' $(date -u)  "**** WMS TESTS ****\n"
# python -m pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/WorkloadManagementSystem/Test_PilotsLoggingClient.py >> clientTestOutputs.txt 2>&1
python $CLIENTINSTALLDIR/DIRAC/tests/Integration/WorkloadManagementSystem/Test_Client_WMS.py $WORKSPACE/TestCode/DIRAC/tests/Integration/WorkloadManagementSystem/sb.cfg >> clientTestOutputs.txt 2>&1
python $CLIENTINSTALLDIR/DIRAC/tests/Integration/WorkloadManagementSystem/Test_SandboxStoreClient.py $WORKSPACE/TestCode/DIRAC/tests/Integration/WorkloadManagementSystem/sb.cfg >> clientTestOutputs.txt 2>&1
python -m pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/WorkloadManagementSystem/Test_JobWrapper.py >> clientTestOutputs.txt 2>&1
python -m pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/WorkloadManagementSystem/Test_PilotsClient.py >> clientTestOutputs.txt 2>&1
## no real tests
python $CLIENTINSTALLDIR/DIRAC/tests/Integration/WorkloadManagementSystem/createJobXMLDescriptions.py >> clientTestOutputs.txt 2>&1
$CLIENTINSTALLDIR/DIRAC/tests/Integration/WorkloadManagementSystem/Test_dirac-jobexec.sh >> clientTestOutputs.txt 2>&1
$CLIENTINSTALLDIR/DIRAC/tests/Integration/WorkloadManagementSystem/Test_TimeLeft.sh >> clientTestOutputs.txt 2>&1


#-------------------------------------------------------------------------------#
echo -e '***' $(date -u)  "**** FTS TESTS ****\n"
pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/DataManagementSystem/Test_Client_FTS3.py >> clientTestOutputs.txt 2>&1


#-------------------------------------------------------------------------------#
echo -e '***' $(date -u)  "**** MONITORING TESTS ****\n"
pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/Monitoring/Test_MonitoringSystem.py >> clientTestOutputs.txt 2>&1


#-------------------------------------------------------------------------------#
echo -e '***' $(date -u)  "**** TS TESTS ****\n"
pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/TransformationSystem/Test_Client_Transformation.py >> clientTestOutputs.txt 2>&1
# pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/TransformationSystem/Test_TS_DFC_Catalog.py >> clientTestOutputs.txt 2>&1


#-------------------------------------------------------------------------------#
echo -e '***' $(date -u)  "**** PS TESTS ****\n"
pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/ProductionSystem/Test_Client_Production.py >> clientTestOutputs.txt 2>&1
pytest $CLIENTINSTALLDIR/DIRAC/tests/Integration/ProductionSystem/Test_Client_TS_Prod.py >> clientTestOutputs.txt 2>&1
