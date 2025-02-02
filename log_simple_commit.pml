/*
Log matching property:
If any two distinct log entries have the same term number and the same index then they will store the exact same command and be identical in all the preceding entries 
simulates a leader getting a new message from a client, must send that message to all other nodes and if gets a successful reply then everyone increments commit index.
*/
#define CLUSTER_SIZE 3
#define MAX_LOG_LENGTH 5
#define FOLLOWER 0
#define CANDIDATE 1
#define LEADER 2
#define FALSE 0
#define TRUE 1

typedef log {
    byte term[MAX_LOG_LENGTH]; //the term of the entry
    byte command[MAX_LOG_LENGTH] //what the command is
}
typedef leader {
    byte id; //the id number of the leader node
    int nextIndex[CLUSTER_SIZE]; //the index that the leader's next log will have
}
typedef node {
    byte currentTerm; //the current election cycle of a node
    byte lastLogIndex; //the index of the last log in a node
}
log logs[CLUSTER_SIZE];
byte status[CLUSTER_SIZE];
node nodes[CLUSTER_SIZE];
bool logsMatch = FALSE;

//Appends the leader's log entries to a node if that node doesn't have as many logs
inline AppendEntries(leaderTerm, prevLogIndex, prevLogTerm, self, res) {  
    d_step {
        bool higherTermThanLeader = leaderTerm < nodes[self].currentTerm;
        bool indexNotMatchPrevLog = logs[self].term[prevLogIndex] != prevLogTerm;
        //Check if we need to append entries
        //If the term is lower than the leaders
        //and their previous log's index doesn't match their previous log, we must append
        if
        :: higherTermThanLeader -> 
            res = FALSE;
        :: indexNotMatchPrevLog -> res = FALSE;
        :: !higherTermThanLeader && !indexNotMatchPrevLog -> 
            res = TRUE;
        fi;
    }


    if //if we are going to append
    :: res ->
        if 
        :: prevLogIndex < nodes[self].lastLogIndex ->
            int j; //prevlogindex is the last index where logs are consistent
            for (j: prevLogIndex + 1 .. MAX_LOG_LENGTH - 1) { //clearing all the log entries in the follower beyond prevLogIndex
                logs[self].term[j] = 0; //0 will indicate not set
                logs[self].command[j] = 0;
            }
            nodes[self].lastLogIndex = prevLogIndex;
        :: prevLogIndex >= nodes[self].lastLogIndex -> skip; //nothing to do if the log index is already higher
        fi;
        int ind = prevLogIndex + 1;
        for (ind: (prevLogIndex + 1) .. (MAX_LOG_LENGTH - 1)) {
            //need to update all logs from the next index after
            //the last log that the node has
            if 
            :: logs[lead.id].term[ind] == 0 -> break;
            :: logs[lead.id].term[ind] != 0 -> 
                logs[self].term[ind] = logs[lead.id].term[ind];
                logs[self].command[ind] = logs[lead.id].command[ind];
                nodes[self].lastLogIndex = nodes[self].lastLogIndex + 1; //increment how long your log is
            fi;
        }
    :: !res -> skip; //nothing to do if we don't need to append
    fi;
}

/*
* Collects information about the leader's logs
* to see if the given node's logs need to be appended to
* If they need to be appended, calls AppendEntries to do so
*/
inline appendEntryInPeer(peer, lastIndex, appended) {
    d_step {
        byte leadId = lead.id;
        int prevIndex = lead.nextIndex[peer];
        prevIndex = prevIndex - 1;
        byte prevTerm = logs[lead.id].term[prevIndex];
        AppendEntries(nodes[leadId].currentTerm, prevIndex, prevTerm, peer, appended);
        if
        :: !appended -> 
            lead.nextIndex[peer] = lead.nextIndex[peer] - 1;
        :: appended -> 
            lead.nextIndex[peer] = lastIndex + 1; //updating appropriate maps, we are now done with this peer
            appended = TRUE;
        fi;
    }
}

//Process to clean up all the logs
active proctype main() {
    //initialize logs for each node - term should be ascending, length should be randomly determined, contents randomly determined
    //need to initialize where term nor command = 0 ever
    int i;
    for (i: 0.. CLUSTER_SIZE - 1) {
        status[i] = FOLLOWER;
    }
    leader lead;
    //INITIALIZATION OF THE LEADER
    status[0] = LEADER;
    logs[0].term[0] = 1; logs[0].term[1] = 1; logs[0].term[2] = 2;
    logs[0].term[3] = 2; logs[0].term[4] = 3;
    logs[0].command[0] = 5; logs[0].command[1] = 5; logs[0].command[2] = 5;
    logs[0].command[3] = 5; logs[0].command[4] = 5;
    nodes[0].lastLogIndex = 4; nodes[0].currentTerm = 3;
    lead.id = 0;
    lead.nextIndex[0] = 5; lead.nextIndex[1] = 5; lead.nextIndex[2] = 5;

    logs[1].term[0] = 1; logs[1].term[1] = 1; logs[1].term[2] = 2;
    logs[1].term[3] = 0; logs[1].term[4] = 0;
    logs[1].command[0] = 5; logs[1].command[1] = 5; logs[1].command[2] = 5;
    logs[1].command[3] = 0; logs[1].command[4] = 0;
    nodes[1].lastLogIndex = 3; nodes[1].currentTerm = 2;

    logs[2].term[0] = 1; logs[2].term[1] = 1; logs[2].term[2] = 1;
    logs[2].term[3] = 1; logs[2].term[4] = 1;
    logs[2].command[0] = 5; logs[2].command[1] = 5; logs[2].command[2] = 1;
    logs[2].command[3] = 1; logs[2].command[4] = 1;
    nodes[2].lastLogIndex = 5; nodes[2].currentTerm = 1;
    //choose a leader, have the leader run appendEntryinPeer on all other nodes. 
    //we want to prove the log matching property
    int i2;
    for(i2: 1 .. CLUSTER_SIZE - 1) {
        bool appended = FALSE;
        appendEntryInPeer(i2, nodes[0].lastLogIndex, appended);
        do
        :: !appended ->
            appendEntryInPeer(i2, nodes[0].lastLogIndex, appended);
        :: appended -> break;
        od;
    }
    //check that the logs all match by going through all nodes
    //and seeing if their logs are the same as the leaders
    bool matches = TRUE;
    int j;
    for(j: 1 .. CLUSTER_SIZE - 1) {
        int entry;
        for(entry: 0 .. nodes[lead.id].lastLogIndex) {
            bool termsDontMatchLeader = logs[j].term[entry] != logs[lead.id].term[entry];
            bool commandsDontMatchLeader = logs[j].command[entry] != logs[lead.id].command[entry];
            bool termsOrCommandsDontMatchLeader = termsDontMatchLeader || commandsDontMatchLeader;
            if
            :: termsOrCommandsDontMatchLeader ->
                matches = FALSE;
            :: !termsOrCommandsDontMatchLeader -> 
                skip;
            
            fi;
        }
    }
    logsMatch = matches;
}

ltl logs_match {
    always(
        eventually(logsMatch == TRUE) //the logs all match
    );
}
