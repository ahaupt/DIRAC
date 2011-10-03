################################################################################
# $HeadURL:  $
################################################################################

import Queue
from DIRAC                                                  import gLogger, S_OK, S_ERROR
from DIRAC.Core.Base.AgentModule                            import AgentModule
from DIRAC.Core.Utilities.ThreadPool                        import ThreadPool

from DIRAC.ResourceStatusSystem                             import CheckingFreqs
from DIRAC.ResourceStatusSystem.Client.ResourceStatusClient import ResourceStatusClient
from DIRAC.ResourceStatusSystem.PolicySystem.PEP            import PEP
from DIRAC.ResourceStatusSystem.Utilities.CS                import getSetup, getExt
from DIRAC.ResourceStatusSystem.Utilities.Utils             import where

__RCSID__ = "$Id:  $"

AGENT_NAME = 'ResourceStatus/StElInspectorAgent'

class StElInspectorAgent( AgentModule ):
  """ Class StElInspectorAgent is in charge of going through StorageElements
      table, and pass StorageElement and Status to the PEP
  """

################################################################################

  def initialize( self ):
    """ Standard constructor
    """

    self.ePepDict = {}

    try:
      
      self.VOExtension = getExt()
      self.setup       = getSetup()[ 'Value' ]
      
      self.rsClient                    = ResourceStatusClient()      
      self.StorageElementsFreqs        = CheckingFreqs[ 'StorageElementsFreqs' ]
      self.StorageElementsToBeChecked  = Queue.Queue()
      self.StorageElementsNamesInCheck = [] 

      self.maxNumberOfThreads = self.am_getOption( 'maxThreadsInPool', 1 )
      self.threadPool         = ThreadPool( self.maxNumberOfThreads,
                                            self.maxNumberOfThreads )
      if not self.threadPool:
        self.log.error( 'Can not create Thread Pool' )
        return S_ERROR( 'Can not create Thread Pool' )  
      
      for _i in xrange( self.maxNumberOfThreads ):
        self.threadPool.generateJobAndQueueIt( self._executeCheck, args = ( None, ) )

      return S_OK()    

    except Exception:
      errorStr = "StElInspectorAgent initialization"
      gLogger.exception( errorStr )
      return S_ERROR( errorStr )

################################################################################

  def execute( self ):
    """
    The main RSInspectorAgent execution method.
    Calls :meth:`DIRAC.ResourceStatusSystem.DB.ResourceStatusDB.getResourcesToCheck` and
    put result in self.StorageElementToBeChecked (a Queue) and in self.StorageElementInCheck (a list)
    """

    try:

      kwargs = { 'columns' : [ 'StorageElementName', 'StatusType', 'Status', \
                              'FormerStatus', 'SiteType', 'TokenOwner' ] }
      resQuery = self.rsClient.getStuffToCheck( 'StorageElement', self.StorageElementsFreqs, **kwargs )

      for seTuple in resQuery[ 'Value' ]:
        
        #THIS IS IMPORTANT !!
        #Ignore all elements with token != RS_SVC
        if seTuple[ 5 ] != 'RS_SVC':
          continue
        
        if ( seTuple[ 0 ], seTuple[ 1 ] ) in self.StorageElementsNamesInCheck:
          continue
        
        resourceL = [ 'StorageElement' ] + seTuple
          
        # the tuple consists on ( SEName, SEStatusType )  
        self.StorageElementsNamesInCheck.insert( 0, ( resourceL[ 1 ], resourceL[ 2 ] ) )
        self.StorageElementsToBeChecked.put( resourceL )
      
      return S_OK()

    except Exception, x:
      errorStr = where( self, self.execute )
      gLogger.exception( errorStr, lException = x )
      return S_ERROR( errorStr )

################################################################################

  def _executeCheck( self, arg ):
    """
    Create instance of a PEP, instantiated popping a resource from lists.
    """

    pep = PEP( self.VOExtension, setup = self.setup )

    while True:

      try:

        toBeChecked        = self.StorageElementsToBeChecked.get()

        pepDict = { 'granularity'  : toBeChecked[ 0 ],
                    'name'         : toBeChecked[ 1 ],
                    'statusType'   : toBeChecked[ 2 ],
                    'status'       : toBeChecked[ 3 ],
                    'formerStatus' : toBeChecked[ 4 ],
                    'siteType'     : toBeChecked[ 5 ],
                    'tokenOwner'   : toBeChecked[ 6 ] }

        gLogger.info( "Checking StorageElement %s, with type/status: %s/%s" % \
                      ( pepDict['name'], pepDict['statusType'], pepDict['status'] ) )
     
        pep.enforce( **pepDict )

        # remove from InCheck list
        self.StorageElementsNamesInCheck.remove( ( pepDict[ 'name' ], pepDict[ 'statusType' ] ) )

      except Exception:
        gLogger.exception( 'StElInspector._executeCheck' )
        try:
          self.StorageElementsNamesInCheck.remove( ( pepDict[ 'name' ], pepDict[ 'statusType' ] ) )
        except IndexError:
          pass

################################################################################
#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF#EOF